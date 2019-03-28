module Xdrgen
  module Generators
    class Rust < Xdrgen::Generators::Base

      def generate
        path = "#{@namespace}_xdr.rs"
        out = @output.open(path)

        render_top_matter out
        render_definitions(out, @top)
        render_bottom_matter out
      end

      private


      def render_top_matter(out)
        out.puts <<~RUST
          /*
            Package #{@namespace || "main"} is generated from:

            - #{@output.source_paths.join("\n  - ")}

           DO NOT EDIT or your changes may be overwritten
          */
          extern crate serde;
          extern crate serde_bytes;
          extern crate serde_xdr;
          #[macro_use]
          extern crate serde_derive;


          use serde_derive::{Deserialize, Serialize};
          use serde_repr::{Deserialize_repr, Serialize_repr};
          use serde_xdr::opaque_data;
        RUST

        out.break
      end

      def render_bottom_matter(out)
        out.puts '/* Bottom matter */'
      end

      def render_definitions(out, node)
        node.definitions.each do |defn|
          render_definition out, defn
        end
      end

      def render_definition(out, defn)
        render_nested_definitions(out, defn)
        render_source_comment(out, defn)
        send("render_#{defn.class.name.demodulize.underscore}", out, defn)
      end

      def render_nested_definitions(out, defn)
        return unless defn.respond_to? :nested_definitions

        defn.nested_definitions.each do |ndefn|
          render_definition out, ndefn
        end
      end

      def render_source_comment(out, defn)
        return if defn.is_a?(AST::Definitions::Namespace)

        out.puts <<~RUST
          /*
             #{name defn} is an XDR #{defn.class.name.demodulize} defined as:

               #{defn.text_value.split(/\n/).join("\n     ")}
          */
        RUST
      end

      # @param [Xdrgen::Output] out
      # @param [Xdrgen::AST::Definitions::Namespace] namespace
      def render_namespace(out, namespace)
        out.puts "/* ==== Namespace: #{namespace.name} ==== */"
        render_definitions out, namespace
        out.break
      end

      # @param [Xdrgen::Output] out
      # @param [Xdrgen::AST::Definitions::Typedef] typedef
      def render_typedef(out, typedef)
        out.puts "type #{name typedef} = #{reference typedef.type};"
        out.break
      end

      # @param [Xdrgen::Output] out
      # @param [Xdrgen::AST::Definitions::Const] const
      def render_const(out, const)
        out.puts "const #{name(const).underscore.upcase}: u64 = #{const.value};"
        out.break
      end

      # @param [Xdrgen::Output] out
      # @param [Xdrgen::AST::Definitions::Struct] struct
      def render_struct(out, struct)
        out.puts "#[derive(Copy, Clone, Debug, Eq, PartialEq, Default, Deserialize, Serialize)]"
        out.puts "pub struct #{name struct} {"
        out.indent do

          struct.members.each do |m|
            out.puts "pub #{field_name m}: #{reference(m.declaration.type)},"
          end
        end
        out.puts '}'
        out.break
      end

      alias render_nested_struct render_struct

      # @param [Xdrgen::Output] out
      # @param [Xdrgen::AST::Definitions::Enum] enum
      def render_enum(out, enum)
        out.puts "#[derive(Copy, Clone, Debug, Eq, PartialEq, Serialize_repr, Deserialize_repr)]"
        out.puts "#[repr(i32)]"
        out.puts "pub enum #{name enum} {"
        out.indent do
          enum.members.each do |m|
            out.puts "#{name m} = #{m.value},"
          end
        end
        out.puts '}'
        out.break
      end

      alias render_nested_enum render_enum

      # @param [Xdrgen::Output] out
      # @param [Xdrgen::AST::Definitions::Union] union
      def render_union(out, union)
        out.puts "#[derive(Copy, Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]"
        out.puts "pub enum #{name union} {"
        out.indent do
          union.arms.each do |arm|
            out.puts arm.void? ? "#{name arm}," : "#{name arm}(#{reference arm.type}),"
          end
        end
        out.puts '}'
        out.break
      end

      alias render_nested_union render_union


      private

      def base_reference(type)
        case type
        when AST::Typespecs::Bool
          'bool'
        when AST::Typespecs::Double
          'f64'
        when AST::Typespecs::Float
          'f32'
        when AST::Typespecs::UnsignedHyper
          'u64'
        when AST::Typespecs::UnsignedInt
          'u32'
        when AST::Typespecs::Hyper
          'i64'
        when AST::Typespecs::Int
          'i32'
        when AST::Typespecs::Quadruple
          raise 'no quadruple support for rust'
        when AST::Typespecs::String
          'String'
        when AST::Typespecs::Opaque
          type.fixed? ? "[u8; #{type.size}]" : 'ByteBuf'
        when AST::Typespecs::Simple, AST::Definitions::Base, AST::Concerns::NestedDefinition
          name type
        else
          raise "Unknown reference type: #{type.class.name}, #{type.class.ancestors}"
        end
      end

      def reference(type)
        base_ref = base_reference type

        case type.sub_type
        when :simple
          base_ref
        when :optional
          "Option<#{base_ref}>"
        when :array
          is_named, size = type.array_size

          # if named, lookup the const definition
          if is_named
            size = name @top.find_definition(size)
          end

          "[#{base_ref}; #{size}]"
        when :var_array
          "Vec<#{base_ref}>" # size
        else
          raise "Unknown sub_type: #{type.sub_type}"
        end

      end

      def name(named)
        parent = name(named.parent_defn) if named.is_a?(AST::Concerns::NestedDefinition)

        base = named.respond_to?(:name) ? named.name : named.text_value

        "#{parent}#{base.underscore.camelize}"
      end

      def field_name(named)
        escape_name named.name.underscore
      end

      def escape_name(name)
        case name
        when 'type' then 'type_'
        else name
        end
      end
    end
  end
end
