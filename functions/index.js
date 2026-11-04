const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getStorage } = require("firebase-admin/storage");
const { getAuth } = require("firebase-admin/auth");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

initializeApp();

const db = getFirestore();
const bucket = getStorage().bucket();
const batchSize = 200;
const parallelDeletes = 20;

async function notifyUser({
  uid,
  notificationId,
  type,
  title,
  body,
  referenceId,
}) {
  const notificationRef = db
    .collection("users")
    .doc(uid)
    .collection("notifications")
    .doc(notificationId);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(notificationRef);
    if (existing.exists) return;
    transaction.create(notificationRef, {
      type,
      title,
      body,
      referenceId,
      createdAt: Timestamp.now(),
      readAt: null,
      pushSent: false,
    });
  });
  const notificationSnapshot = await notificationRef.get();
  if (!notificationSnapshot.exists || notificationSnapshot.get("pushSent")) {
    return;
  }

  const tokenSnapshot = await db
    .collection("users")
    .doc(uid)
    .collection("notification_tokens")
    .get();
  const tokenDocuments = tokenSnapshot.docs.filter(
    (document) => typeof document.get("token") === "string",
  );
  const tokens = tokenDocuments.map((document) => document.get("token"));
  if (tokens.length === 0) {
    await notificationRef.update({ pushSent: true });
    return;
  }

  for (let index = 0; index < tokens.length; index += 500) {
    const tokenBatch = tokens.slice(index, index + 500);
    const documentBatch = tokenDocuments.slice(index, index + 500);
    try {
      const response = await getMessaging().sendEachForMulticast({
        tokens: tokenBatch,
        notification: { title, body },
        data: {
          type,
          notificationId,
          referenceId: referenceId || "",
        },
        android: {
          notification: {
            channelId: "zap_mexico_notifications",
            sound: "default",
          },
        },
        apns: {
          payload: { aps: { sound: "default" } },
        },
      });

      const staleTokens = [];
      response.responses.forEach((result, tokenIndex) => {
        const code = result.error?.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          staleTokens.push(documentBatch[tokenIndex].ref);
        } else if (!result.success) {
          logger.error("Could not deliver a push notification", {
            uid,
            code,
          });
        }
      });
      if (staleTokens.length > 0) {
        const batch = db.batch();
        staleTokens.forEach((reference) => batch.delete(reference));
        await batch.commit();
      }
    } catch (error) {
      logger.error("Push notification delivery failed", { uid, error });
    }
  }
  await notificationRef.update({ pushSent: true });
}

exports.notifyAdminsOfNewListing = onDocumentCreated(
  {
    document: "businesses/{businessId}",
    region: "us-central1",
  },
  async (event) => {
    const listing = event.data?.data();
    if (!listing || listing.status !== "pending") return;

    const isService = listing.listingType === "service";
    const admins = await db.collection("admins").get();
    await Promise.all(
      admins.docs.map((admin) =>
        notifyUser({
          uid: admin.id,
          notificationId: `new-listing-${event.params.businessId}`,
          type: "admin_new_request",
          title: isService ? "Nuevo prestador por revisar" : "Nuevo negocio por revisar",
          body: `${listing.name || "Una publicación"} · ${listing.city || ""}`,
          referenceId: event.params.businessId,
        }),
      ),
    );
  },
);

exports.notifyListingDecision = onDocumentUpdated(
  {
    document: "businesses/{businessId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (
      !before ||
      !after ||
      before.status === after.status ||
      !["approved", "rejected"].includes(after.status) ||
      typeof after.createdBy !== "string" ||
      !after.createdBy ||
      after.createdBy === "demo-user"
    ) {
      return;
    }

    const isService = after.listingType === "service";
    const approved = after.status === "approved";
    await notifyUser({
      uid: after.createdBy,
      notificationId: `listing-${event.params.businessId}-${after.status}`,
      type: approved ? "business_approved" : "business_rejected",
      title: isService
        ? approved
          ? "Prestador aprobado"
          : "Prestador rechazado"
        : approved
          ? "Negocio aprobado"
          : "Negocio rechazado",
      body: `${after.name || "Tu publicación"}: ${
        approved
          ? "ya aparece en el directorio."
          : after.adminComment || "revisa la información y contacta al administrador."
      }`,
      referenceId: event.params.businessId,
    });
  },
);

exports.expireMarketplaceProducts = onSchedule(
  {
    schedule: "every day 00:00",
    timeZone: "America/Mexico_City",
    region: "us-central1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    let totalDeleted = 0;
    const expirationCutoff = Timestamp.fromMillis(
      Timestamp.now().toMillis() - 5 * 24 * 60 * 60 * 1000,
    );

    while (true) {
      const expired = await db
        .collection("marketplace_products")
        .where("createdAt", "<=", expirationCutoff)
        .orderBy("createdAt")
        .limit(batchSize)
        .get();

      if (expired.empty) break;

      const products = expired.docs;
      for (let index = 0; index < products.length; index += parallelDeletes) {
        const group = products.slice(index, index + parallelDeletes);
        await Promise.all(
          group.map(async (product) => {
            const sellerUid = product.get("sellerUid");
            if (typeof sellerUid !== "string" || sellerUid.length === 0) {
              logger.error("Marketplace listing has no valid seller UID", {
                productId: product.id,
              });
              throw new Error(`Invalid sellerUid on product ${product.id}`);
            }

            await notifyUser({
              uid: sellerUid,
              notificationId: `marketplace-expired-${product.id}`,
              type: "marketplace_expired",
              title: "Tu publicación de Marketplace venció",
              body: `${product.get("name") || "Tu producto"} se eliminó después de cinco días.`,
              referenceId: product.id,
            });
            await bucket.deleteFiles({
              prefix: `marketplace/${sellerUid}/${product.id}/`,
            });
            await product.ref.delete();
            totalDeleted += 1;
          }),
        );
      }
    }

    logger.info("Expired Marketplace listings removed", { totalDeleted });
  },
);

exports.deleteAccount = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid || request.auth.token.firebase?.sign_in_provider === "anonymous") {
      throw new HttpsError(
        "unauthenticated",
        "Inicia sesión con una cuenta registrada para eliminarla.",
      );
    }

    const businesses = db.collection("businesses");
    while (true) {
      const ownedBusinesses = await businesses
        .where("createdBy", "==", uid)
        .limit(batchSize)
        .get();
      if (ownedBusinesses.empty) break;

      for (
        let index = 0;
        index < ownedBusinesses.docs.length;
        index += parallelDeletes
      ) {
        const group = ownedBusinesses.docs.slice(index, index + parallelDeletes);
        await Promise.all(
          group.map(async (business) => {
            const requests = db
              .collection("catalog_requests")
              .where("businessId", "==", business.id);
            while (true) {
              const relatedRequests = await requests.limit(batchSize).get();
              if (relatedRequests.empty) break;
              const requestBatch = db.batch();
              relatedRequests.docs.forEach((document) =>
                requestBatch.delete(document.ref),
              );
              await requestBatch.commit();
            }

            await bucket.deleteFiles({
              prefix: `businesses/${business.id}/`,
            });
            await db.recursiveDelete(business.ref);
          }),
        );
      }
    }

    const products = db
      .collection("marketplace_products")
      .where("sellerUid", "==", uid);
    while (true) {
      const ownedProducts = await products.limit(batchSize).get();
      if (ownedProducts.empty) break;

      for (
        let index = 0;
        index < ownedProducts.docs.length;
        index += parallelDeletes
      ) {
        const group = ownedProducts.docs.slice(index, index + parallelDeletes);
        await Promise.all(
          group.map(async (product) => {
            await bucket.deleteFiles({
              prefix: `marketplace/${uid}/${product.id}/`,
            });
            await db.recursiveDelete(product.ref);
          }),
        );
      }
    }

    await bucket.deleteFiles({ prefix: `user_profiles/${uid}/` });
    await db.recursiveDelete(db.collection("users").doc(uid));
    await db.collection("admins").doc(uid).delete();
    await getAuth().deleteUser(uid);

    return { deleted: true };
  },
);
