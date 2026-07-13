import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// ─────────────────────────────────────────────
// MIDDLEWARE
// ─────────────────────────────────────────────
app.use(
  cors({
    origin: [
      "http://localhost:3000",
      "http://10.0.2.2:3000",
      "mkmu://",
    ],
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "Cookie"],
  })
);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ─────────────────────────────────────────────
// ROUTES
// ─────────────────────────────────────────────
app.get("/", (req, res) => {
  res.send("MKMU API Server is running. Visit /health for status.");
});

// ─────────────────────────────────────────────
// HEALTH CHECK
// ─────────────────────────────────────────────
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    app: "MKMU Server (Clean)",
    timestamp: new Date().toISOString(),
  });
});

// ─────────────────────────────────────────────
// START SERVER
// ─────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`
  ╔══════════════════════════════════════╗
  ║         MKMU API Server              ║
  ║     Running on port ${PORT}             ║
  ║     Health: /health                  ║
  ╚══════════════════════════════════════╝
  `);
});
