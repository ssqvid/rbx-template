import isentinel from "@isentinel/eslint-config";

export default isentinel({
    react: true,
    rules: {
        "no-spaced-func": "off",
    },
    spellCheck: false,
    test: true,
});
