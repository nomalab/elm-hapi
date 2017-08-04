# elm-hapi

Configure and run a Hapi server though an Elm effect module. **Does not support the full Hapi API**.

## Install

**Requires Node 6.4.0 or later**

**Version 0.0.x, not production ready yet**

Since this package is both an effect module and using Native code, we cannot push to the Elm registry, so you will have to install it directly from GitHub.

## Try it

```bash
# Install repo
git clone git@github.com:nomalab/elm-hapi.git
cd elm-hapi
# Install node and elm packages
yarn install
yarn deps
# Start server
yarn build && yarn start
# (replace "yarn" with "npm run" if you are using NPM)
```

Then open [http://localhost:8080/](http://localhost:8080/) and enjoy!
