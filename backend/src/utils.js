import crypto from "crypto";

/**
 * Calculate SHA-256 hash from a buffer
 * @param {Buffer} buffer - Input buffer
 * @returns {string} - Hex-encoded SHA-256 hash
 */
export function sha256FromBuffer(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex");
}

/**
 * Calculate SHA-256 hash from a stream
 * @param {Stream} stream - Input stream
 * @returns {Promise<string>} - Hex-encoded SHA-256 hash
 */
export function sha256FromStream(stream) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash("sha256");
    stream.on("data", (chunk) => hash.update(chunk));
    stream.on("end", () => resolve(hash.digest("hex")));
    stream.on("error", reject);
  });
}

/**
 * Format bytes to human-readable format
 * @param {number} bytes - Number of bytes
 * @returns {string} - Formatted string
 */
export function formatBytes(bytes) {
  if (bytes === 0) return "0 Bytes";
  const k = 1024;
  const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + " " + sizes[i];
}

/**
 * Validate file type
 * @param {string} mimetype - MIME type
 * @param {Array<string>} allowedTypes - Array of allowed MIME types
 * @returns {boolean} - Whether the file type is allowed
 */
export function validateFileType(mimetype, allowedTypes = []) {
  if (allowedTypes.length === 0) return true;
  return allowedTypes.includes(mimetype);
}

/**
 * Generate a unique filename
 * @param {string} originalName - Original filename
 * @returns {string} - Unique filename with timestamp
 */
export function generateUniqueFilename(originalName) {
  const timestamp = Date.now();
  const ext = originalName.split(".").pop();
  const name = originalName.replace(`.${ext}`, "");
  return `${name}-${timestamp}.${ext}`;
}
