// src/availability/availability.controller.ts
import { Controller, Get, Query, BadRequestException } from '@nestjs/common';
import { AvailabilityService } from './availability.service';

@Controller({ path: 'availability', version: '1' })
export class AvailabilityController {
  constructor(private availability: AvailabilityService) {}

  /**
   * Optionnel : slots "naïfs" (minutes + libellés HH:mm + isoUtc).
   * Utile pour du debug ou un front ultra-simple.
   *
   * Exemple :
   *   GET /v1/availability/slots-naive?providerId=PROV_ID&from=2025-10-17T00:00:00Z&to=2025-10-24T00:00:00Z&step=30&duration=60
   *
   * NOTE : Les routes officielles restent :
   *   - GET /v1/providers/:id/slots                     (public slots riches)
   *   - GET /v1/providers/me/availability               (weekly, auth)
   *   - POST /v1/providers/me/availability              (weekly, auth)
   *   - POST/GET/DELETE /v1/providers/me/time-offs...   (time-offs, auth)
   */
  @Get('slots-naive')
  async publicSlotsNaive(
    @Query('providerId') providerId?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('step') step?: string,
    @Query('duration') duration?: string,
  ) {
    if (!providerId) {
      throw new BadRequestException('providerId is required');
    }
    if (!from || !to) {
      throw new BadRequestException('from/to are required ISO strings');
    }
    const stepMin = Number.isFinite(Number(step)) ? Number(step) : 30;
    const durMin  = Number.isFinite(Number(duration)) ? Number(duration) : undefined;

    return this.availability.publicSlotsNaive(providerId, from, to, stepMin, durMin);
  }
}
