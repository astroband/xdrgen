module Xdrgen::AST
  module Definitions
    class EnumMember < Base
      extend Memoist

      include Concerns::Named
      include Concerns::Contained

      def value
        unsigned_value = defined_value || auto_value

        # enums are signed in xdr, so...
        # convert to twos complement value
        [unsigned_value].pack("l>").unpack1("l>")
      end

      memoize def enum
        find_ancestors(Enum).last
      end

      def auto_value
        index = enum.members.index(self)
        if index == 0
          0
        else
          # use the previous members value + 1
          enum.members[index - 1].value + 1
        end
      end

      def defined_value
        return if value_n.terminal?

        case value_n.val
        when Constant
          value_n.val.value
        when Identifier
          namespace.find_enum_value(value_n.val.name).defined_value
        end
      end
    end
  end
end
