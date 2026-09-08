# frozen_string_literal: true

require "pagy"

# Light pagination defaults. The API layer overrides per request:
# per_page <= 100, defaults to 25.
Pagy::DEFAULT[:items] = 25
Pagy::DEFAULT[:max_items] = 100
Pagy::DEFAULT[:size] = []
Pagy::DEFAULT[:overflow] = :empty_page
