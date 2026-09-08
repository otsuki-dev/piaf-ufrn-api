# frozen_string_literal: true

module Api::V1::Paginatable
  extend ActiveSupport::Concern

  DEFAULT_ITEMS = 25
  MAX_ITEMS = 100

  private

  def page_size
    requested = params[:per_page].to_i
    return DEFAULT_ITEMS if requested <= 0

    [ requested, MAX_ITEMS ].min
  end

  def pagy_meta(pagy)
    {
      pagination: {
        page: pagy.page,
        per_page: pagy.limit,
        count: pagy.count,
        pages: pagy.pages,
        prev_page: pagy.prev,
        next_page: pagy.next
      },
      headers: pagy_headers(pagy)
    }
  end

  def pagy_collection(collection)
    pagy, records = pagy(collection, limit: page_size)
    set_pagy_headers(pagy)
    [ records, pagy ]
  end

  def set_pagy_headers(pagy)
    response.set_header "X-Page", pagy.page.to_s
    response.set_header "X-Per-Page", pagy.limit.to_s
    response.set_header "X-Total", pagy.count.to_s
    response.set_header "X-Total-Pages", pagy.pages.to_s
    response.set_header "X-Next-Page", pagy.next.to_s
    response.set_header "X-Prev-Page", pagy.prev.to_s
  end

  def pagy_headers(pagy)
    {
      "X-Page" => pagy.page.to_s,
      "X-Per-Page" => pagy.limit.to_s,
      "X-Total" => pagy.count.to_s,
      "X-Total-Pages" => pagy.pages.to_s
    }
  end
end
