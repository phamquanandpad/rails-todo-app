require "pagy/extras/metadata"
require "pagy/extras/overflow"

Pagy::DEFAULT[:limit] = 20
Pagy::DEFAULT[:max_limit] = 100
Pagy::DEFAULT[:overflow] = :empty_page
