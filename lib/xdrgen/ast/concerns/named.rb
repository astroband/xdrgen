module Xdrgen::AST
  module Concerns
    module Named
      delegate :name, to: :identifier

      def namespaces
        return [] unless is_a?(Contained)
        find_ancestors(Concerns::Namespace)
      end

      def fully_qualified_name
        namespaces.map(&:name) + [name]
      end
    end
  end
end
