"use strict";

const { Contract } = require("fabric-contract-api");

class HashContract extends Contract {
  async Init(ctx) {
    console.info("HashContract initialized");
    return;
  }

  /**
   * Record a file's hash and metadata on the blockchain
   * @param {Context} ctx - Transaction context
   * @param {string} fileID - Unique file identifier
   * @param {string} objectKey - MinIO object key
   * @param {string} sha256 - SHA-256 hash of the file
   * @param {string} uploader - User who uploaded the file
   * @param {string} metadataJson - JSON string of file metadata
   */
  async recordFile(ctx, fileID, objectKey, sha256, uploader, metadataJson) {
    const exists = await this.fileExists(ctx, fileID);
    if (exists) {
      throw new Error(`File ${fileID} already recorded`);
    }

    const record = {
      fileID,
      objectKey,
      sha256,
      uploader,
      metadata: JSON.parse(metadataJson || "{}"),
      timestamp: new Date().toISOString(),
    };

    await ctx.stub.putState(fileID, Buffer.from(JSON.stringify(record)));

    // Emit event for file recording
    ctx.stub.setEvent("FileRecorded", Buffer.from(JSON.stringify(record)));

    console.info(`File ${fileID} recorded with hash ${sha256}`);
    return JSON.stringify(record);
  }

  /**
   * Verify and retrieve a file's record from the blockchain
   * @param {Context} ctx - Transaction context
   * @param {string} fileID - Unique file identifier
   */
  async verifyFile(ctx, fileID) {
    const data = await ctx.stub.getState(fileID);
    if (!data || data.length === 0) {
      throw new Error(`File ${fileID} does not exist`);
    }
    return data.toString();
  }

  /**
   * Check if a file exists on the blockchain
   * @param {Context} ctx - Transaction context
   * @param {string} fileID - Unique file identifier
   */
  async fileExists(ctx, fileID) {
    const data = await ctx.stub.getState(fileID);
    return !!data && data.length > 0;
  }

  /**
   * Get all recorded files
   * @param {Context} ctx - Transaction context
   */
  async getAllFiles(ctx) {
    const iterator = await ctx.stub.getStateByRange("", "");
    const all = [];

    while (true) {
      const res = await iterator.next();

      if (res.value && res.value.value.toString()) {
        const Key = res.value.key;
        let Record;
        try {
          Record = JSON.parse(res.value.value.toString("utf8"));
        } catch (err) {
          console.error(`Error parsing record for key ${Key}:`, err);
          Record = res.value.value.toString("utf8");
        }
        all.push({ Key, Record });
      }

      if (res.done) {
        await iterator.close();
        return JSON.stringify(all);
      }
    }
  }
}

module.exports = HashContract;
