// src/uploads/uploads.controller.ts
import {
  Body,
  Controller,
  Post,
  Delete,
  Param,
  Req,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Get,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt.guard';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiTags, ApiConsumes, ApiBody } from '@nestjs/swagger';
import type { Request } from 'express';
import { diskStorage, type StorageEngine } from 'multer';
import { existsSync, mkdirSync } from 'fs';
import { extname, join } from 'path';
import { randomUUID } from 'crypto';
import { UploadsService } from './uploads.service';
import { ReqUser } from '../auth/req-user.decorator';

@ApiTags('uploads')
@ApiBearerAuth()
@Controller({ path: 'uploads', version: '1' })
@UseGuards(JwtAuthGuard)
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  /**
   * Get current storage configuration
   */
  @Get('config')
  async getConfig() {
    return {
      provider: this.uploadsService.getProvider(),
    };
  }

  /**
   * Upload file to local storage
   * The file is saved to ./public/uploads and a public URL is returned
   */
  @Post('local')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          const dir = join(process.cwd(), 'public', 'uploads');
          if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
          cb(null, dir);
        },
        filename: (_req, file, cb) => {
          const uniqueName = `${Date.now()}-${randomUUID()}${extname(file.originalname)}`;
          cb(null, uniqueName);
        },
      }) as StorageEngine,
      limits: {
        fileSize: 10 * 1024 * 1024, // 10 MB max
      },
      fileFilter: (_req, file, cb) => {
        // Allow images and common document types
        const allowedMimes = [
          'image/jpeg',
          'image/png',
          'image/gif',
          'image/webp',
          'application/pdf',
        ];
        if (allowedMimes.includes(file.mimetype)) {
          cb(null, true);
        } else {
          cb(new Error(`File type ${file.mimetype} is not allowed`), false);
        }
      },
    }),
  )
  async uploadLocal(
    @UploadedFile() file: Express.Multer.File,
    @Req() req: Request,
  ) {
    // Get the correct host, considering reverse proxy headers
    const forwardedHost = req.get('x-forwarded-host');
    const forwardedProto = req.get('x-forwarded-proto');

    const host = forwardedHost || req.get('host') || 'localhost';
    const protocol = forwardedProto || req.protocol || 'https';

    return this.uploadsService.uploadLocal(file, host, protocol);
  }

  /**
   * Get a presigned URL for direct S3 upload
   * Client uploads directly to S3 using this URL
   */
  @Post('presign')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['mimeType'],
      properties: {
        mimeType: { type: 'string', example: 'image/jpeg' },
        folder: { type: 'string', example: 'uploads' },
        ext: { type: 'string', example: 'jpg' },
      },
    },
  })
  async presign(
    @ReqUser() user: { id: string },
    @Body() body: { mimeType: string; folder?: string; ext?: string },
  ) {
    return this.uploadsService.getPresignedUrl(
      user.id,
      body.mimeType,
      body.folder,
      body.ext,
    );
  }

  /**
   * Upload file directly to S3 (server-side upload)
   * Use this when you need server-side processing before upload
   */
  @Post('s3')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
        folder: {
          type: 'string',
        },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: 10 * 1024 * 1024, // 10 MB max
      },
      fileFilter: (_req, file, cb) => {
        const allowedMimes = [
          'image/jpeg',
          'image/png',
          'image/gif',
          'image/webp',
          'application/pdf',
        ];
        if (allowedMimes.includes(file.mimetype)) {
          cb(null, true);
        } else {
          cb(new Error(`File type ${file.mimetype} is not allowed`), false);
        }
      },
    }),
  )
  async uploadToS3(
    @UploadedFile() file: Express.Multer.File,
    @ReqUser() user: { id: string },
    @Body() body: { folder?: string },
  ) {
    return this.uploadsService.uploadToS3(file, user.id, body.folder);
  }

  /**
   * Delete a file from storage
   */
  @Delete(':key')
  async deleteFile(
    @Param('key') key: string,
    @Body() body: { provider?: 'local' | 's3' },
  ) {
    await this.uploadsService.delete(key, body.provider);
    return { success: true };
  }
}
