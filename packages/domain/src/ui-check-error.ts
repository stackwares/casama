// SPDX-License-Identifier: Apache-2.0
/** Why a UI or card was refused, in words a bot or a plugin's author can act on. */
export class UiCheckError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "UiCheckError";
  }
}
