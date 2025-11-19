import { createParamDecorator, ExecutionContext, UnauthorizedException } from '@nestjs/common';

export const ReqUser = createParamDecorator(
  (data: string | undefined, ctx: ExecutionContext) => {
    const req = ctx.switchToHttp().getRequest();
    const user = req.user;

    // Si pas d'utilisateur attaché à la requête, lever une erreur
    if (!user) {
      throw new UnauthorizedException('User not authenticated. Please provide a valid token.');
    }

    // Normalise pour offrir `id` même si la stratégie ne renvoie que `sub`
    const normalized =
      user?.id != null
        ? user
        : {
            ...user,
            id: user?.sub ?? user?.userId ?? user?.uid,
          };

    // Vérifier que l'id est défini après normalisation
    if (!normalized?.id) {
      throw new UnauthorizedException('Unable to identify user from token. Token may be invalid or malformed.');
    }

    return data ? normalized?.[data] : normalized;
  },
);
