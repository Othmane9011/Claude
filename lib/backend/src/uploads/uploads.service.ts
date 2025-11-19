// src/uploads/uploads.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';
import { existsSync, mkdirSync, unlinkSync } from 'fs';
import { join, extname } from 'path';

export type StorageProvider = 'local' | 's3';

export interface UploadResult {
  url: string;
  key: string;
  provider: StorageProvider;
}

export interface PresignResult {
  url: string;
  key: string;
  bucket: string;
  publicUrl?: string;
}

@Injectable()
export class UploadsService {
  private readonly s3: S3Client;
  private readonly storageProvider: StorageProvider;
  private readonly localDir: string;
  private readonly publicBaseUrl: string;

  // S3 config
  private readonly s3Bucket: string;
  private readonly s3Endpoint: string;
  private readonly s3PublicEndpoint: string;
  private readonly s3UseObjectAcl: boolean;
  private readonly s3ForcePathStyle: boolean;

  constructor(private readonly config: ConfigService) {
    // Determine storage provider
    this.storageProvider = (this.config.get<string>('STORAGE_PROVIDER') || 'local') as StorageProvider;

    // Local storage config
    this.localDir = join(process.cwd(), 'public', 'uploads');
    this.publicBaseUrl = this.config.get<string>('PUBLIC_URL') || '';

    // S3 config (for OVH Object Storage or AWS S3)
    this.s3Bucket = this.config.get<string>('S3_BUCKET') || '';
    this.s3Endpoint = this.config.get<string>('S3_ENDPOINT') || '';
    this.s3PublicEndpoint = this.config.get<string>('S3_PUBLIC_ENDPOINT') || this.s3Endpoint;
    this.s3UseObjectAcl = this.config.get<string>('S3_USE_OBJECT_ACL')?.toLowerCase() === 'true';
    this.s3ForcePathStyle = this.config.get<string>('S3_FORCE_PATH_STYLE')?.toLowerCase() === 'true';

    // Initialize S3 client (even if using local, for presign endpoint)
    this.s3 = new S3Client({
      region: this.config.get<string>('AWS_REGION') || 'gra',
      endpoint: this.s3Endpoint || undefined,
      forcePathStyle: this.s3ForcePathStyle,
      credentials: this.s3Endpoint ? {
        accessKeyId: this.config.get<string>('AWS_ACCESS_KEY_ID') || '',
        secretAccessKey: this.config.get<string>('AWS_SECRET_ACCESS_KEY') || '',
      } : undefined,
    });

    // Ensure local directory exists
    if (!existsSync(this.localDir)) {
      mkdirSync(this.localDir, { recursive: true });
    }
  }

  /**
   * Get the storage provider being used
   */
  getProvider(): StorageProvider {
    return this.storageProvider;
  }

  /**
   * Upload a file to local storage
   */
  async uploadLocal(
    file: Express.Multer.File,
    requestHost?: string,
    requestProtocol?: string,
  ): Promise<UploadResult> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Generate unique filename
    const uniqueName = `${Date.now()}-${randomUUID()}${extname(file.originalname)}`;
    const filePath = join(this.localDir, uniqueName);

    // File is already saved by multer diskStorage, just need to return URL
    // The filename is in file.filename when using diskStorage

    // Build public URL
    let publicUrl: string;
    if (this.publicBaseUrl) {
      // Use configured PUBLIC_URL (recommended for production behind proxy)
      publicUrl = `${this.publicBaseUrl.replace(/\/+$/, '')}/uploads/${file.filename}`;
    } else if (requestHost) {
      // Fallback to request host
      const protocol = requestProtocol || 'https';
      publicUrl = `${protocol}://${requestHost}/uploads/${file.filename}`;
    } else {
      // Last resort
      publicUrl = `/uploads/${file.filename}`;
    }

    return {
      url: publicUrl,
      key: file.filename,
      provider: 'local',
    };
  }

  /**
   * Upload a file directly to S3
   */
  async uploadToS3(
    file: Express.Multer.File,
    userId: string,
    folder: string = 'uploads',
  ): Promise<UploadResult> {
    if (!this.s3Bucket) {
      throw new BadRequestException('S3 bucket not configured');
    }

    const cleanFolder = folder.replace(/^\/+|\/+$/g, '');
    const ext = extname(file.originalname);
    const key = `${cleanFolder}/${userId}/${randomUUID()}${ext}`;

    const putInput: any = {
      Bucket: this.s3Bucket,
      Key: key,
      Body: file.buffer,
      ContentType: file.mimetype,
    };

    if (this.s3UseObjectAcl) {
      putInput.ACL = 'public-read';
    }

    await this.s3.send(new PutObjectCommand(putInput));

    // Build public URL
    const publicUrl = this.buildS3PublicUrl(key);

    return {
      url: publicUrl,
      key,
      provider: 's3',
    };
  }

  /**
   * Generate a presigned URL for direct S3 upload from client
   */
  async getPresignedUrl(
    userId: string,
    mimeType: string,
    folder: string = 'uploads',
    ext: string = '',
  ): Promise<PresignResult> {
    if (!this.s3Bucket) {
      throw new BadRequestException('S3 bucket not configured. Set S3_BUCKET environment variable.');
    }

    const cleanFolder = folder.replace(/^\/+|\/+$/g, '');
    const cleanExt = ext.replace(/^\./, '');
    const key = `${cleanFolder}/${userId}/${randomUUID()}${cleanExt ? '.' + cleanExt : ''}`;

    const putInput: any = {
      Bucket: this.s3Bucket,
      Key: key,
      ContentType: mimeType,
    };

    if (this.s3UseObjectAcl) {
      putInput.ACL = 'public-read';
    }

    const put = new PutObjectCommand(putInput);
    const url = await getSignedUrl(this.s3, put, { expiresIn: 900 });

    return {
      url,
      key,
      bucket: this.s3Bucket,
      publicUrl: this.buildS3PublicUrl(key),
    };
  }

  /**
   * Delete a file from storage
   */
  async delete(key: string, provider?: StorageProvider): Promise<void> {
    const targetProvider = provider || this.storageProvider;

    if (targetProvider === 'local') {
      const filePath = join(this.localDir, key);
      if (existsSync(filePath)) {
        unlinkSync(filePath);
      }
    } else {
      if (!this.s3Bucket) {
        throw new BadRequestException('S3 bucket not configured');
      }
      await this.s3.send(new DeleteObjectCommand({
        Bucket: this.s3Bucket,
        Key: key,
      }));
    }
  }

  /**
   * Build the public URL for an S3 object
   */
  private buildS3PublicUrl(key: string): string {
    if (this.s3PublicEndpoint) {
      // OVH style: https://s3.gra.cloud.ovh.net/bucket/key
      return `${this.s3PublicEndpoint.replace(/\/+$/, '')}/${this.s3Bucket}/${key}`;
    }
    // AWS style: https://bucket.s3.region.amazonaws.com/key
    const region = this.config.get<string>('AWS_REGION') || 'us-east-1';
    return `https://${this.s3Bucket}.s3.${region}.amazonaws.com/${key}`;
  }
}
