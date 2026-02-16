# Inertia.js Lucky Adapter

Create server-driven single page applications using [Lucky](https://luckyframework.org) and Vue3, React, or Svelte. No client routing, no store.

To use Inertia.js you need a server side adapter (like this) and a client side adapter, such as [inertia-vue](https://github.com/inertiajs/inertia-vue). Follow the installation instructions below to get started, and don't forget to check out the [Inertia.js Documentation](https://inertiajs.com/) itself.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     lucky_inertia:
       github: watzon/lucky_inertia
   ```

2. Run `shards install`

3. Include the shard in your `src/shards.cr` file
    ```crystal
    # Require your shards here
    require "lucky"
    require "avram/lucky"
    require "carbon"
    require "lucky_inertia" # <- Put it here
    ```

4. Run the installer task
    ```shell
    # For Vue3
    lucky inertia.setup vue

    # For React
    lucky inertia.setup react

    # For Svelte
    lucky inertia.setup svelte

    # Or the bring-your-own-framework method
    lucky intertia.setup
    ```

5. If you selected a framework to be installed, import the newly created `src/js/inertia.js` file in your `app.js`
    ```js
    require("@rails/ujs").start();
    require("./inertia"); // <- put it here
    ```

6. Be sure to update your build file to work with the framework you're using. With Vue3 and Laravel Mix as an example:
    ```js
      const path = require("path")
      
      //..

      mix
        .setPublicPath("public")
        .js("src/js/app.js", "js")
        .alias({ '@': path.resolve('src/js') })
        .sourceMaps()
        .vue()
    ```

## Usage

Inertia facilitates communication between your frontend SPA and your backend web server, in this case Lucky. What this means is that you can directly render your Vue, React, or Svelte pages from your Lucky actions. For example:

```crystal
class App::Index < InertiaAction
  get "/" do
    inertia "Index"
  end
end
```

The above will tell the Inertia.js frontend to open the page registered as `Index`. Using the default installation this will be the file located at `src/js/Pages/Index.{vue,svelte,jsx}`.

### Passing Props

You can pass data to your frontend components using the `props` parameter:

```crystal
class Users::Show < InertiaAction
  get "/users/:id" do
    user = UserQuery.find(id)
    inertia "Users/Show", props: {
      user: user.to_json,
      can_edit: user.id == current_user.id
    }
  end
end
```

## Advanced Features

### Shared Data

Share data across all Inertia responses using the `inertia_share` macro in your base action:

```crystal
abstract class InertiaAction < Lucky::Action
  include Inertia::SharedData
  
  inertia_share(
    auth: -> { current_user.try(&.to_json) },
    flash: -> { flash.to_h }
  )
end
```

Now `auth` and `flash` will be available as props in all your Inertia pages.

### Form Validation with Operations

Include `Inertia::Operations` to automatically handle validation errors with the POST-Redirect-GET pattern:

```crystal
abstract class InertiaAction < Lucky::Action
  include Inertia::Operations
end

class Users::Create < InertiaAction
  post "/users" do
    SaveUser.create(params) do |operation, user|
      if operation.saved?
        flash.success = "User created!"
        redirect to: Users::Show.with(user.id)
      else
        # Errors automatically stored in flash and shared on next request
        store_errors_in_flash(operation)
        flash.failure = "Please fix the errors"
        redirect to: Users::New
      end
    end
  end
end
```

Errors will be automatically available in your frontend as `errors` prop:

```vue
<template>
  <form @submit.prevent="submit">
    <input v-model="form.name" />
    <span v-if="errors.name">{{ errors.name[0] }}</span>
    
    <button type="submit">Save</button>
  </form>
</template>

<script setup>
import { useForm, usePage } from '@inertiajs/vue3'

const { errors } = usePage().props

const form = useForm({
  name: ''
})

function submit() {
  form.post('/users')
}
</script>
```

### Flash Messages

Include `Inertia::FlashIntegration` to automatically share flash messages:

```crystal
abstract class InertiaAction < Lucky::Action
  include Inertia::FlashIntegration
end
```

Flash messages will be available as the `flash` prop in your components.

### Lazy Data Evaluation

Defer expensive computations until they're actually needed:

```crystal
class Users::Index < InertiaAction
  get "/users" do
    inertia "Users/Index", props: {
      users: Inertia.lazy { User.all.map(&.to_json) },  # Only loaded when requested
      total: User.count
    }
  end
end
```

### Partial Reloads

Combine lazy props with partial reloads for better performance. On the frontend:

```javascript
// Only reload the "users" prop
router.reload({ only: ['users'] })

// Reload everything except "archived_users"
router.reload({ except: ['archived_users'] })
```

### Request Detection Helpers

Check if the current request is an Inertia request:

```crystal
class Users::Index < InertiaAction
  get "/users" do
    if inertia?
      # This is an Inertia XHR request
      inertia "Users/Index", props: { users: users }
    else
      # This is a regular page load
      inertia "Users/Index", props: { users: users }
    end
  end
end
```

Available helpers:
- `inertia?` - Check if request is from Inertia
- `inertia_partial?` - Check if request is a partial reload
- `partial_only` - Get array of props requested in partial reload
- `partial_except` - Get array of props excluded in partial reload

### External Redirects

Handle external URL redirects properly:

```crystal
class OAuth::Callback < InertiaAction
  get "/auth/callback" do
    # Inertia will handle this with a 409 response
    handle_redirect("https://external-site.com/welcome")
  end
end
```

### View Data

Pass data to your root layout that isn't included in the Inertia page props:

```crystal
class Users::Show < InertiaAction
  get "/users/:id" do
    user = UserQuery.find(id)
    inertia "Users/Show", 
      props: { user: user.to_json },
      view_data: { page_title: "User Profile - #{user.name}" }
  end
end
```

### Configuration

Configure Inertia in `config/inertia.cr`:

```crystal
Inertia.configure do |settings|
  # Asset versioning for cache busting
  settings.version = "v1.0.0"
  
  # Server-side rendering
  settings.ssr_enabled = false
  settings.ssr_url = "http://localhost:13714"
  settings.ssr_timeout = 30.seconds
  
  # Data management
  settings.deep_merge_shared_data = false
  settings.include_flash = true
  settings.include_errors = true
end
```

### Testing

Use the provided spec helpers to test your Inertia responses:

```crystal
require "inertia/spec_helpers"

include Inertia::SpecHelpers

describe "Users::Index" do
  it "renders inertia component" do
    response = client.get("/users", headers: inertia_headers)
    
    assert_inertia_component(response, "Users/Index")
    assert_inertia_props(response) do |props|
      props["users"].as_a.size.should eq(10)
    end
  end
  
  it "handles partial reloads" do
    response = client.get(
      "/users",
      headers: inertia_partial_headers("Users/Index", only: ["users"])
    )
    
    assert_inertia_component(response, "Users/Index")
  end
end
```

### SSR

SSR support requires some changes to your codebase that are best handled manually. Most of the changes are detailed in the [Server Side Rendering](https://inertiajs.com/server-side-rendering) side of the Inertia documentation, so I'd recommend following the instructions there to get the SSR components installed for your framework of choice. Listed below are the instructions specifically for Vue.

1. Install the server-side rendering dependencies
    ```shell
    yarn add @vue/server-renderer
    ```

2. Install the `@inertiajs/server` package to add SSR support to Inertia itself
    ```shell
    yarn add @inertiajs/server
    ```

3. Create the SSR JS entrypoint
    ```shell
    touch src/js/ssr.js
    ```

4. This file will look a lot like your `inertia.js` file, with the main exception being this file will not run in the browser. Add anything that is in `inertia.js` to this file as well, just make sure anything you're using is SSR compatible.
    ```js
    import { createSSRApp, h } from 'vue'
    import { renderToString } from '@vue/server-renderer'
    import { createInertiaApp } from '@inertiajs/inertia-vue3'
    import createServer from '@inertiajs/server'

    createServer((page) => createInertiaApp({
      page,
      render: renderToString,
      resolve: name => require(`./Pages/${name}`),
      setup({ app, props, plugin }) {
        return createSSRApp({
          render: () => h(app, props),
        }).use(plugin)
      },
    }))
    ```

5. Install `webpack-node-externals`
    ```shell
    yarn add webpack-node-externals --dev
    ```

6. Create `webpack.ssr.mix.js`. This is going to be your SSR pipeline entrypoint.
    ```shell
    touch webpack.ssr.mix.js
    ```

    Here is an example of what you should have in this file:
    ```js
    const path = require('path')
    const mix = require('laravel-mix')
    const webpackNodeExternals = require('webpack-node-externals')

    mix
      .options({ manifest: false })
      .js('src/js/ssr.js', 'public/js')
      .vue({ version: 3, options: { optimizeSSR: true } })
      .alias({ '@': path.resolve('src/js') })
      .webpackConfig({
        target: 'node',
        externals: [webpackNodeExternals()],
      })
    ```

7. Enable SSR in your `config/inertia.cr` file by setting `settings.ssr_enabled = true`

The following steps are optional, but really help streamline your build pipeline.

8. Install `concurrently`
    ```shell
    yarn add concurrently --dev
    ```

9. Add the following to the `scripts` section of your `package.json`, overwriting what's there currently
    ```json
    {
      // ...
      "scripts": {
        "dev": "concurrently \"yarn run watch:base\" \"yarn run watch:ssr\"",
        "dev:base": "yarn run mix",
        "dev:ssr": "yarn run mix --mix-config=webpack.ssr.mix.js",
        "watch": "concurrently \"yarn run watch:base\" \"yarn run watch:ssr\"",
        "watch:base": "yarn run mix watch",
        "watch:ssr": "yarn run mix watch --mix-config=webpack.ssr.mix.js",
        "prod": "yarn run mix --production && yarn run mix --production --mix-config=webpack.ssr.mix.js"
      }
      // ...
    }
    ```

10. Add the following line to `Procfile` and `Procfile.dev`
      ```procfile
      ssr: node public/js/ssr.js
      ```

And that's it. A lot of steps, but you should now have a working Vue3 SSR application.

## Contributing

1. Fork it (<https://github.com/watzon/lucky_inertia/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
