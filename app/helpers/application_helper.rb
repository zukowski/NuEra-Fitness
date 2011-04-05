module ApplicationHelper
  def squash_adjustments(adjustments)
    adjustments.inject({}) do |squash,adjustment|
      if squash.has_key? adjustment.label
        squash[adjustment.label] += adjustment.amount
      else
        squash[adjustment.label] = adjustment.amount
      end
      squash
    end
  end
end
