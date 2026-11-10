/** Encryption at rest (D-136): which key wraps workspace data keys on this server. */
import { AwsKmsKeyWrapper, contentKeys, type KeyWrapper, LocalKeyWrapper } from "@kasama/db";
import type { Env } from "./env.ts";

export function contentKeyWrapper(env: Env): KeyWrapper | null {
  if (env.CONTENT_KMS_KEY_ID) {
    if (!env.CONTENT_KMS_REGION || !env.AWS_ACCESS_KEY_ID || !env.AWS_SECRET_ACCESS_KEY)
      throw new Error(
        "CONTENT_KMS_KEY_ID needs CONTENT_KMS_REGION, AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY",
      );
    return new AwsKmsKeyWrapper({
      keyId: env.CONTENT_KMS_KEY_ID,
      region: env.CONTENT_KMS_REGION,
      accessKeyId: env.AWS_ACCESS_KEY_ID,
      secretAccessKey: env.AWS_SECRET_ACCESS_KEY,
      sessionToken: env.AWS_SESSION_TOKEN,
      endpoint: env.CONTENT_KMS_ENDPOINT,
    });
  }
  if (env.CONTENT_ENCRYPTION_KEY)
    return new LocalKeyWrapper(
      env.CONTENT_ENCRYPTION_KEY,
      (env.CONTENT_ENCRYPTION_KEY_PREVIOUS ?? "")
        .split(",")
        .map((k) => k.trim())
        .filter(Boolean),
    );
  return null;
}

export function configureContentKeys(env: Env) {
  contentKeys.configure(contentKeyWrapper(env));
}
