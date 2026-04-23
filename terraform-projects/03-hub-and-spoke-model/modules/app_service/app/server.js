// ==========================
// 🔴 Application Insights (SAFE INIT)
// ==========================
const appInsights = require("applicationinsights");

let client = null;

if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  appInsights.setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING)
    .setAutoCollectRequests(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectExceptions(true)
    .setAutoCollectPerformance(true)
    .start();

  client = appInsights.defaultClient;
  console.log("App Insights initialized");
} else {
  console.warn("App Insights NOT configured");
}

// 🔴 Safe wrapper (never crash app)
function trackExceptionSafe(err) {
  try {
    if (client && typeof client.trackException === "function") {
      client.trackException({ exception: err });
    }
  } catch (e) {
    console.error("AI exception tracking failed:", e.message);
  }
}

// ==========================
// 🔴 App setup
// ==========================
const express = require("express");
const multer = require("multer");
const axios = require("axios");
const FormData = require("form-data");

const app = express();
const upload = multer();

const API_BASE_URL = process.env.API_BASE_URL;
const APP_VERSION = process.env.APP_VERSION || "dev";
const BUILD_TIME = process.env.BUILD_TIME || new Date().toISOString();

console.log("App starting...");
console.log(`App version: ${APP_VERSION}, build: ${BUILD_TIME}`);

// 🔴 Validate config
if (!API_BASE_URL) {
  console.error("API_BASE_URL not set");
  process.exit(1);
}

// ==========================
// ✅ Health endpoint
// ==========================
app.get("/health", (req, res) => {
  res.status(200).send("OK");
});

// ==========================
// ✅ Version endpoint
// ==========================
app.get("/version", (req, res) => {
  res.json({
    version: APP_VERSION,
    build_time: BUILD_TIME,
    service: "app-service-proxy",
    node: process.version
  });
});

// ==========================
// ✅ Static frontend
// ==========================
app.use(express.static("public"));

// ==========================
// 🚀 Upload API
// ==========================
app.post("/api/upload", upload.single("file"), async (req, res) => {
  try {
    const { name, email, age } = req.body;

    // 🔴 validation
    if (!name || !email || !age) {
      return res.status(400).json({ error: "missing fields" });
    }

    if (!req.file) {
      return res.status(400).json({ error: "file required" });
    }

    console.log("Received file:", req.file.originalname);

    // =========================
    // ✅ Step 1: Create user
    // =========================
    const userRes = await axios.post(
      `${API_BASE_URL}/user`,
      {
        name,
        email,
        age: parseInt(age)
      },
      {
        timeout: 15000
      }
    );

    const user = userRes.data;

    // =========================
    // ✅ Step 2: Upload file
    // =========================
    const formData = new FormData();

    formData.append("name", name);
    formData.append("email", email);
    formData.append("age", age);

    formData.append("file", req.file.buffer, {
      filename: req.file.originalname,
      contentType: req.file.mimetype
    });

    console.log("Forwarding file to Go API...");

    await axios.post(
      `${API_BASE_URL}/upload/${user.id}`,
      formData,
      {
        headers: formData.getHeaders(),
        timeout: 20000
      }
    );

    res.json({
      message: "Success",
      userId: user.id
    });

  } catch (err) {
    console.error("Upload flow failed:", err.message);

    // 🔴 Safe tracking (won’t crash app)
    trackExceptionSafe(err);

    // 🔴 Timeout handling
    if (err.code === "ECONNABORTED") {
      return res.status(504).json({
        error: "Request timed out"
      });
    }

    // 🔴 Upstream error
    if (err.response) {
      return res.status(500).json({
        error: "Upstream service failed",
        details: err.response.data
      });
    }

    // 🔴 Generic error
    res.status(500).json({
      error: "Internal error",
      details: err.message
    });
  }
});

// ==========================
// 🚀 Start server
// ==========================
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});