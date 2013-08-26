require 'cache_replace/version'

module CacheReplace
  ERROR_MISSING_KEY_OR_BLOCK = "You must either pass a `replace` key or a block to render_cached."
  
  # Supports 5 options:
  #
  # 1. Single partial to replace. 
  #    "inner" is the key name and "_inner.*" is the partial file name.
  #
  #   render_cached "container", replace: "inner"
  #
  # 2. Array of partials to replace
  #
  #   render_cached "container", replace: ["inner"]
  #
  # 3. Map of keys to replace with values
  #
  #   render_cached "container", replace: {key_name: a_helper_method(object)}
  #
  # 4. Yield to a hash of keys to replace with values
  #
  #   render_cached "container" do
  #     {key_name: a_helper_method(object)}
  #   end
  #
  # 5. Render a collection with Procs for replace values.
  #
  #   render_cached "partial", collection: objects, replace: { key_name: ->(object){a_method(object)} }
  #
  def render_cached(partial, options={})
    replace = options.delete(:replace)
    collection = options.delete(:collection)
    fragment = render(partial, options)

    case replace
    when Hash
      if collection
        fragment = replace_collection(fragment, collection, replace)
      else
        replace_from_hash fragment, replace
      end
    when NilClass
      raise ArgumentError.new(ERROR_MISSING_KEY_OR_BLOCK) unless block_given?
      replace_from_hash fragment, yield
    else
      replace = *replace
      replace.each do |key|
        fragment.gsub! cache_replace_key(key), render(key, options)
      end
    end

    raw fragment
  end

  CACHE_REPLACE_KEY_OPEN  = '<cr '

  # string key containing the partial file name or placeholder key.
  # It is a tag that should never be returned to be rendered by the
  # client, but if so, it will be hidden since CR is not a valid html tag.
  def cache_replace_key(key)
    raw "#{CACHE_REPLACE_KEY_OPEN}#{key.to_s}>"
  end

private

  def replace_from_hash(fragment, hash)
    hash.each do |key, value|
      fragment.gsub! cache_replace_key(key), value.to_s
    end
  end

  def replace_item_hash(fragment, item, hash)
    hash.each do |key, value|
      fragment.gsub! cache_replace_key(key), value.call(item)
    end
  end

  def replace_collection(fragment, collection, replace)
    html = ""

    collection.each do |item|
      item_fragment = fragment.dup
      replace_item_hash(item_fragment, item, replace)
      html << item_fragment
    end

    html
  end
end
