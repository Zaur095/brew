# typed: true
# frozen_string_literal: true

module RuboCop
  module Cop
    module Cask
      class NoOverrides < Base
        extend T::Sig
        include CaskHelp

        ON_SYSTEM_METHODS = RuboCop::Cask::Constants::ON_SYSTEM_METHODS
        MESSAGE = <<~EOS
          Do not use top-level `%<stanza>s` stanza as the default, add an `on_{system}` block instead.
          Use `:or_older` or `:or_newer` to specify a range of macOS versions.
        EOS

        def on_cask(cask_block)
          return if (cask_stanzas = cask_block.toplevel_stanzas).empty?
          # Skip if there are no `on_*` blocks.
          return unless (on_blocks = cask_stanzas.select { |s| ON_SYSTEM_METHODS.include?(s.stanza_name) }).any?

          cask_stanzas.each do |stanza|
            # Skip if the stanza is itself an `on_*` block.
            next unless RuboCop::Cask::Constants::STANZA_ORDER.include?(stanza.stanza_name)
            # Skip if the stanza we detect is already in an `on_*` block.
            next if stanza.parent_node.block_type? && ON_SYSTEM_METHODS.include?(stanza.parent_node.method_name)
            # Skip if the stanza outside of a block is not also in an `on_*` block.
            next if on_system_stanzas(on_blocks).none?(stanza.stanza_name)

            add_offense(stanza.source_range, message: format(MESSAGE, stanza: stanza.stanza_name))
          end
        end

        def on_system_stanzas(on_system)
          names = []
          method_nodes = on_system.map(&:method_node)
          method_nodes.each do |node|
            next unless node.block_type?

            node.child_nodes.each do |child|
              child.each_node(:send) do |send_node|
                next if ON_SYSTEM_METHODS.include?(send_node.method_name)

                names << send_node.method_name
              end
            end
          end
          names
        end
      end
    end
  end
end
