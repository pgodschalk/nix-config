// The limits arrive as string literals and are coerced here, because a
// bare placeholder in value position is not valid JavaScript: `@`
// starts a decorator, so the file would not parse before substitution
// and no language server could check it.
const bodyLimit = Number("@bodyLimit@");
const subjectLimit = Number("@subjectLimit@");

export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    // config-conventional ships 100 for both, and these are characters
    // rather than lines.
    "body-max-line-length": [2, "always", bodyLimit],
    "header-max-length": [2, "always", subjectLimit],
  },
};
