module ValueSortSupport
  extend ActiveSupport::Concern

  def multi_value_sort(hash)
    hash.each_with_object({}) do |(k,v),h|
      if v.is_a? Array
        v=v.sort do |a,b|
          multi_value_sort_compare(a,b)
        end
      end
      h[k]=v
    end
  end

  private
    def multi_value_sort_compare(a,b)
      return -1 if a.nil? && !b.nil?
      return 1 if !a.nil? && b.nil?
      return a.class.to_s <=> b.class.to_s if a.class!=b.class
      return a <=> b if a.is_a? Comparable
      if a.class==Hash
        keys = (a.keys + b.keys).uniq.sort
        keys.each do |key|
          c = multi_value_sort_compare(a[key],b[key])
          return c if c!=0
        end
      end
      return 0
    end
end
