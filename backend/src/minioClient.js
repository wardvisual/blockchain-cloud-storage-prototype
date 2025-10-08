import Minio from "minio";
import dotenv from "dotenv";

dotenv.config();

const client = new Minio.Client({
  endPoint: process.env.MINIO_ENDPOINT || "127.0.0.1",
  port: parseInt(process.env.MINIO_PORT || "9000"),
  useSSL: false,
  accessKey: process.env.MINIO_ACCESS_KEY || "minioadmin",
  secretKey: process.env.MINIO_SECRET_KEY || "minioadmin",
});

/**
 * Ensure bucket exists, create if not
 * @param {string} bucket - Bucket name
 */
export async function ensureBucket(bucket) {
  try {
    const exists = await client.bucketExists(bucket);
    if (!exists) {
      await client.makeBucket(bucket, "us-east-1");
      console.log(`Bucket '${bucket}' created successfully`);
    }
  } catch (err) {
    console.error("Error ensuring bucket:", err);
    throw err;
  }
}

/**
 * Upload a stream to MinIO
 * @param {string} bucket - Bucket name
 * @param {string} objectName - Object key/name
 * @param {Buffer|Stream} stream - Data stream or buffer
 * @param {number} size - Size of the object
 */
export function uploadStream(bucket, objectName, stream, size) {
  return client.putObject(bucket, objectName, stream, size);
}

/**
 * Get an object stream from MinIO
 * @param {string} bucket - Bucket name
 * @param {string} objectName - Object key/name
 */
export function getObjectStream(bucket, objectName) {
  return client.getObject(bucket, objectName);
}

/**
 * Delete an object from MinIO
 * @param {string} bucket - Bucket name
 * @param {string} objectName - Object key/name
 */
export function removeObject(bucket, objectName) {
  return client.removeObject(bucket, objectName);
}

/**
 * List all objects in a bucket
 * @param {string} bucket - Bucket name
 */
export async function listObjects(bucket) {
  const objectsStream = client.listObjects(bucket, "", true);
  const objects = [];

  return new Promise((resolve, reject) => {
    objectsStream.on("data", (obj) => objects.push(obj));
    objectsStream.on("error", reject);
    objectsStream.on("end", () => resolve(objects));
  });
}

export default client;
