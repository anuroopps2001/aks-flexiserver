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
    .setAutoCollectConsole(true, true)
    .start();

  client = appInsights.defaultClient;
  console.log("✅ App Insights initialized");
} else {
  console.warn("⚠️ App Insights NOT configured");
}

// 🔴 Safe wrapper
function trackExceptionSafe(err) {
  try {
    if (client) {
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
console.log("AI Connection:", process.env.APPLICATIONINSIGHTS_CONNECTION_STRING);

// 🔴 Validate config
if (!API_BASE_URL) {
  console.error("API_BASE_URL not set");
  process.exit(1);
}

// ==========================
// ✅ TEST ENDPOINT (VERY IMPORTANT)
// ==========================
app.get("/test-ai", (req, res) => {
  console.log("🔥 /test-ai endpoint hit");

  if (client) {
    client.trackEvent({ name: "test-event" });

    client.trackTrace({
      message: "Test trace from App Service",
      severity: 1
    });

    client.trackMetric({
      name: "test-metric",
      value: 42
    });

    console.log("✅ Telemetry sent to App Insights");
  } else {
    console.log("❌ AI client not initialized");
  }

  res.send("AI test triggered");
});

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

    if (!name || !email || !age) {
      return res.status(400).json({ error: "missing fields" });
    }

    if (!req.file) {
      return res.status(400).json({ error: "file required" });
    }

    console.log("Received file:", req.file.originalname);

    const start = Date.now();

    // Step 1
    const userRes = await axios.post(
      `${API_BASE_URL}/user`,
      {
        name,
        email,
        age: parseInt(age)
      },
      { timeout: 15000 }
    );

    const user = userRes.data;

    // Step 2
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

    // 🔥 Track dependency manually (important)
    if (client) {
      client.trackDependency({
        target: API_BASE_URL,
        name: "upload-flow",
        data: "upload-api",
        duration: Date.now() - start,
        success: true,
        dependencyTypeName: "HTTP"
      });
    }

    res.json({
      message: "Success",
      userId: user.id
    });

  } catch (err) {
  console.error("Upload flow failed:", {
    message: err.message,
    status: err.response?.status,
    data: err.response?.data
  });

  trackExceptionSafe(err);

  // Timeout
  if (err.code === "ECONNABORTED") {
    return res.status(504).json({ error: "Request timed out" });
  }

  // Upstream error (AKS / Storage / API)
  if (err.response) {
    const status = err.response.status;

    return res.status(status).json({
      error: "Upstream service failed",
      upstreamStatus: status
    });
  }

  // Fallback
  return res.status(500).json({
    error: "Internal error"
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
