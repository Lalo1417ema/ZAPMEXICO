const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

initializeApp();

const db = getFirestore();
const bucket = getStorage().bucket();
const batchSize = 200;
const parallelDeletes = 20;

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
