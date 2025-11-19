Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AdoptService } from './adopt.service';
import { CreateAdoptPostDto } from './dto/create-adopt-post.dto';
import { UpdateAdoptPostDto } from './dto/update-adopt-post.dto';
import { FeedQueryDto } from './dto/feed.dto';
import { SwipeDto } from './dto/swipe.dto';
import { AuthGuard } from '@nestjs/passport';

@ApiTags('Adopt')
@Controller({ path: 'adopt', version: '1' })
export class AdoptController {
  constructor(private readonly service: AdoptService) {}

  // Public feed (APPROVED only)
  @Get('feed')
  async feed(@Query() q: FeedQueryDto) {
    return this.service.feed(null, q);
  }

  // Public detail (APPROVED only)
  @Get('posts/:id')
  async getOne(@Param('id') id: string) {
    return this.service.getPublic(id);
  }

  // Authenticated CRUD
  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Post('posts')
  async create(@Req() req: any, @Body() dto: CreateAdoptPostDto) {
    return this.service.create(req.user, dto);
  }

  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Patch('posts/:id')
  async update(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateAdoptPostDto) {
    return this.service.update(req.user, id, dto);
  }

  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
@@ -58,26 +57,34 @@ export class AdoptController {
  async remove(@Req() req: any, @Param('id') id: string) {
    return this.service.remove(req.user, id);
  }

  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Get('my/posts')
  async myPosts(@Req() req: any) {
    return this.service.listMine(req.user);
  }

  // Swipe
  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Post('posts/:id/swipe')
  async swipe(@Req() req: any, @Param('id') id: string, @Body() dto: SwipeDto) {
    return this.service.swipe(req.user, id, dto);
  }

  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Get('my/likes')
  async myLikes(@Req() req: any) {
    return this.service.myLikes(req.user);
  }

  // Likes reçus sur mes annonces (approchantes du Tinder-like)
  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @Get('my/requests')
  async myRequests(@Req() req: any) {
    return this.service.incomingRequests(req.user);
  }
}
