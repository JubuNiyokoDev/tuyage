module.exports = {
    env: {
        es6: true,
        node: true,
    },
    parserOptions: {
        ecmaVersion: 2018,
    },
    extends: [
        "eslint:recommended",
        "google",
    ],
    rules: {
        "no-restricted-globals": ["error", "name", "length"],
        "prefer-arrow-callback": "error",
        "quotes": ["error", "double", {"allowTemplateLiterals": true}],
        "indent": ["error", 4],
        "comma-dangle": ["error", "always-multiline"],
        "object-curly-spacing": ["error", "never"],
        "max-len": ["error", {"code": 80}],
    },
    overrides: [
        {
            files: ["**/*.spec.*"],
            env: {
                mocha: true,
            },
            rules: {},
        },
    ],
    globals: {},
};
