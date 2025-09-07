import isentinel from "@isentinel/eslint-config";

export default isentinel({
    react: true,
    rules: {
		"camelcase": "off",
		"max-lines-per-function": "off",
		"no-restricted-syntax": "off",
		"no-spaced-func": "off",
		"roblox/no-user-defined-lua-tuple": "off",
		"ts/naming-convention": "off",
    },
    spellCheck: false,
    test: true,
});
