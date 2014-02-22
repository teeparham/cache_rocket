[![Gem Version](https://badge.fury.io/rb/cache_rocket.png)][gem]
[![Build Status](https://api.travis-ci.org/neighborland/cache_rocket.png)][build]
[![Coverage Status](https://coveralls.io/repos/neighborland/cache_rocket/badge.png)][coverage]
[![Code Climate](https://codeclimate.com/github/neighborland/cache_rocket.png)][climate]

[gem]: http://badge.fury.io/rb/cache_rocket
[build]: https://travis-ci.org/neighborland/cache_rocket
[coverage]: https://coveralls.io/r/neighborland/cache_rocket
[climate]: https://codeclimate.com/github/neighborland/cache_rocket

## Rails rendering extension for server-side html caching

CacheRocket improves fragment caching efficiency in Rails. 
CacheRocket allows caching more generic html fragments and allowing the contents of the cached fragments 
to be replaced with dynamic content.

### Install

Add the gem to your Gemfile:

```ruby
gem 'cache_rocket'
```

Include the CacheRocket module so your views can use the `render_cached` method.
Most likely you would put this in your `ApplicationHelper`:

```ruby
include CacheRocket
```

### Use

CacheRocket allows you to cache a fragment of html and replace inner html. 
You inject dynamic content into a static, cached outer partial. 
You cache the donut and replace the donut hole.

Assume you have some html that you would like to cache, but cannot because of some uncacheable code nested in the DOM.
For example:

##### file.html.haml:
```haml
= render 'outer'
```

##### _outer.html.haml:
```haml
.lots
  .of
    .htmls
      = render 'inner'
```

##### _inner.html.haml:
```haml
= uncacheable_content
```

In the scenario above, you can't cache anything. With `cache_rocket`, you can. Replace `render`
with `render_cached` in `file`, specify the partial to replace in `outer`, and cache `outer`:

##### file.html.haml:
```haml
= render_cached 'outer', replace: 'inner'
```

##### _outer.html.haml:
```haml
- cache 'outer' do
  .lots
    .of
      .htmls
        = cache_replace_key 'inner'
```

##### _inner.html.haml:
``` haml
= uncacheable_content
```

In this example, you could remove the `_inner.html.haml` file altogether, like so:

##### file.html.haml:
```haml
= render_cached 'outer', replace: { inner: uncacheable_content }
```

##### _outer.html.haml:
```haml
- cache 'outer' do
  .lots
    .of
      .htmls
        = cache_replace_key 'inner'
```

### Options

`render_cached` supports several styles of arguments:

#### Single partial to replace

```ruby
render_cached 'outer', replace: 'inner'
```

#### Array of partials to replace
```ruby
render_cached 'outer', replace: ['inner', 'footer']
```

#### Hash of keys to replace with values
```ruby
render_cached 'outer', replace: { key_name: a_helper_method(object) }
```

#### Block containing a hash of keys to replace with values
```ruby
render_cached 'outer' do
  { key_name: a_helper_method(object) }
end
```

#### Render a collection with hash of keys, using a Proc for each collection item
```ruby
render_cached 'outer', collection: objects,
  replace: { key_name: ->(object) { a_helper_method(object) } }
```

#### Render a collection with block syntax
```ruby
render_cached 'outer', collection: objects do
  { key_name: ->(object) { a_helper_method(object) } }
end
```

#### Render a collection with block syntax with multiple keys
```ruby
render_cached 'outer', collection: objects do
  { 
    key_1: ->(object) { a_helper_method(object) },
    key_2: ->(item) { item.name },
  }
end
```

### YMMV

`cache_rocket` is not magic. It should not be used in all situations.
Benchmark your page rendering times before and after to see if it helps.

### Benefits

#### More server-side caching

See the example above.

#### Use far less memory

Typically, one would key the `users/bio` partial on the `user` object like so:

##### users/bio.haml:
```haml
- cache [user, 'bio'] do
  .lots-of-htmls
    = user.bio
```

```haml
= render 'users/bio'
```

With 1000 users, there are 1000 cached items. This can use a lot of memory.
Instead we can cache the `users/bio` partial once and replace the content we need using
`cache_replace`. With 1000 users, we use 1/1000th the memory.

##### users/bio.haml:
```haml
- cache('users/bio') do
  .lots-of-htmls
    = cache_replace_key :bio
```

```haml
= render_cached 'users/bio', replace: { bio: user.bio }
```

#### Simpler cache keys

If you have a cache key containing multiple models, it will generally be very inefficient:
```haml
- cache(user, other_user) do
  = render 'common_interests'
```

If the cached content is rarely retrieved, `cache_replace` can help:

```haml
- cache('common_interests') do
  .htmls
    = cache_replace_key :something
```

```haml
= render 'common_interests', replace: { something: 'common_interests/inner' }
```

#### Faster first page loads

By caching common html, you ensure that you will render cached content the first time a model-dependent
fragment is rendered. See the `Use far less memory` section above for an example.

### References

* Slides from Boulder Ruby presentation: http://www.slideshare.net/teeparham/rails-html-fragment-caching-with-cache-rocket
* Rails cache benchmark test app: https://github.com/teeparham/cache_benchmark
