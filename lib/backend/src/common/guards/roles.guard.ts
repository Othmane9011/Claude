import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY, Role } from '../decorators/roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!requiredRoles?.length) return true;

    const req = context.switchToHttp().getRequest();
    const role = (req?.user?.role ?? '').toString().toUpperCase() as Role;
    if (!role) return false;

    return requiredRoles.includes(role);
  }
}
