# raplh-playground

## Project
- Express 5 in-memory todo REST API (CommonJS)
- Entry: `src/index.js` — exports `{ app, reset }`
- Single source file, no lint/typecheck setup

## Test
```bash
npm test
```
- Mocha + Chai (`assert`) + Supertest; single file `test/test.js`
- `beforeEach(reset)` isolates state for every test
- Custom timeout: `--timeout 5000` (set in package.json scripts)

## Conventions
- No comments in implementation code
- Express route handlers: validate input, return proper status codes
- Report errors with file path and line number
- Preserve backward compatibility
