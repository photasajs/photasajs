import type { DefineComponent } from "vue";

/** Stub for vue-tsc: upstream SFC types fail under Vue 3.5 / TS 5.9. */
export const JsonTreeView: DefineComponent<
    Record<string, unknown>,
    Record<string, unknown>,
    unknown
> = {} as DefineComponent;
