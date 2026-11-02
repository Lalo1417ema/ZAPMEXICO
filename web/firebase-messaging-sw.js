importScripts(
  "https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js",
);

firebase.initializeApp({
  apiKey: "AIzaSyDw7T8E0Ecjt0YCLZkIxIuIUp72cF59Bws",
  appId: "1:814376171285:web:a3998c24ec33ab1de1db1c",
  authDomain: "zap2026-382a1.firebaseapp.com",
  messagingSenderId: "814376171285",
  projectId: "zap2026-382a1",
  storageBucket: "zap2026-382a1.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  self.registration.showNotification(notification.title || "Zap México", {
    body: notification.body || "",
    icon: "/icons/Icon-192.png",
    data: payload.data || {},
  });
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow("/"));
});
