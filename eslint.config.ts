import isentinel from "@isentinel/eslint-config";

export default isentinel({
    react: true,
    rules: {
		"no-restricted-syntax": "off",
        "no-spaced-func": "off",
		"ts/no-require-imports": "off",
    },
    spellCheck: false,
    test: true,
});
