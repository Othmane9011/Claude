import { Body, Controller, Get, Patch, Req, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt.guard';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UpdateMeDto } from './dto/update-me.dto';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller({ path: 'users', version: '1' })
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  async me(@Req() req: any) {
    return this.users.findMe(req.user.sub);
  }

  @Patch('me')
  async updateMe(@Req() req: any, @Body() dto: UpdateMeDto) {
    return this.users.updateMe(req.user.sub, dto);
  }
}
