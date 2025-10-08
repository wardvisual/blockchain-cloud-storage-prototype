import express from "express";
import multer from "multer";
import cors from "cors";
import { v4 as uuidv4 } from "uuid";
import dotenv from "dotenv";
import { sha256FromBuffer } from "./utils.js";
import { ensureBucket, uploadStream, getObjectStream } from "./minioClient.js";
import { connectGateway } from "./fabricClient.js";
dotenv.config();

const app = express();
const upload = multer({ storage: multer.memoryStorage() });
const BUCKET = process.env.MINIO_BUCKET || "files";
const PORT = parseInt(process.env.PORT || "3000");

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

/**
 * Upload file endpoint
 * POST /upload
 * Uploads file to MinIO and records hash on Fabric blockchain
 */
app.post("/upload", upload.single("file"), async (req, res) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ error: "No file provided" });
    }

    console.log(`Processing upload for file: ${file.originalname}`);

    // Ensure MinIO bucket exists
    await ensureBucket(BUCKET);

    // Generate unique file ID and compute hash
    const fileID = uuidv4();
    const sha256 = sha256FromBuffer(file.buffer);
    const objectName = `${fileID}-${file.originalname}`;

    console.log(`File ID: ${fileID}, SHA-256: ${sha256}`);

    // Upload to MinIO
    await uploadStream(BUCKET, objectName, file.buffer, file.size);
    console.log(`Uploaded to MinIO: ${objectName}`);

    // Submit to Fabric blockchain
    const { gateway, contract } = await connectGateway();
    const metadata = {
      originalName: file.originalname,
      mime: file.mimetype,
      size: file.size,
    };

    const uploader = req.headers["x-user"] || req.body.uploader || "user1";

    const result = await contract.submitTransaction(
      "recordFile",
      fileID,
      objectName,
      sha256,
      uploader,
      JSON.stringify(metadata)
    );

    await gateway.disconnect();
    console.log(`Recorded on blockchain: ${fileID}`);

    return res.json({
      ok: true,
      fileID,
      objectName,
      sha256,
      uploader,
      metadata,
      message: "File uploaded and recorded successfully",
    });
  } catch (err) {
    console.error("Upload error:", err);
    return res.status(500).json({ error: err.message || err.toString() });
  }
});

/**
 * Verify file integrity endpoint
 * GET /verify/:fileID
 * Retrieves file from MinIO, computes hash, and compares with blockchain record
 */
app.get("/verify/:fileID", async (req, res) => {
  try {
    const fileID = req.params.fileID;
    console.log(`Verifying file: ${fileID}`);

    // Query blockchain for file record
    const { gateway, contract } = await connectGateway();
    const result = await contract.evaluateTransaction("verifyFile", fileID);
    await gateway.disconnect();

    const record = JSON.parse(result.toString());
    console.log(`Retrieved record from blockchain:`, record);

    // Fetch object from MinIO and compute hash
    const stream = await getObjectStream(BUCKET, record.objectKey);
    const chunks = [];

    for await (const chunk of stream) {
      chunks.push(chunk);
    }

    const buffer = Buffer.concat(chunks);
    const computed = sha256FromBuffer(buffer);

    // Compare hashes
    const ok = computed === record.sha256;

    console.log(`Verification result: ${ok ? "PASS" : "FAIL"}`);
    console.log(`Stored hash: ${record.sha256}`);
    console.log(`Computed hash: ${computed}`);

    return res.json({
      ok,
      fileID,
      record,
      computed,
      match: ok,
      message: ok
        ? "File integrity verified"
        : "File integrity check FAILED - file may have been tampered with",
    });
  } catch (err) {
    console.error("Verify error:", err);
    return res.status(500).json({ error: err.message || err.toString() });
  }
});

/**
 * Get all files endpoint
 * GET /files
 * Returns all files recorded on the blockchain
 */
app.get("/files", async (req, res) => {
  try {
    console.log("Fetching all files from blockchain");

    const { gateway, contract } = await connectGateway();
    const result = await contract.evaluateTransaction("getAllFiles");
    await gateway.disconnect();

    const files = JSON.parse(result.toString());

    return res.json({
      ok: true,
      count: files.length,
      files,
    });
  } catch (err) {
    console.error("Get files error:", err);
    return res.status(500).json({ error: err.message || err.toString() });
  }
});

/**
 * Get specific file metadata endpoint
 * GET /file/:fileID
 * Returns metadata for a specific file from blockchain
 */
app.get("/file/:fileID", async (req, res) => {
  try {
    const fileID = req.params.fileID;
    console.log(`Fetching file metadata: ${fileID}`);

    const { gateway, contract } = await connectGateway();
    const result = await contract.evaluateTransaction("verifyFile", fileID);
    await gateway.disconnect();

    const record = JSON.parse(result.toString());

    return res.json({
      ok: true,
      fileID,
      record,
    });
  } catch (err) {
    console.error("Get file error:", err);
    return res.status(500).json({ error: err.message || err.toString() });
  }
});

// Start server
app.listen(PORT, () => {
  console.log("=".repeat(50));
  console.log(`Server listening on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Upload endpoint: POST http://localhost:${PORT}/upload`);
  console.log(`Verify endpoint: GET http://localhost:${PORT}/verify/:fileID`);
  console.log(`Files list: GET http://localhost:${PORT}/files`);
  console.log("=".repeat(50));
});

export default app;
