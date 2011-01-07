class ReportTransformer
  def self.transformations
    [ZeroToOne, OneToTwo]
  end

  def self.apply(report)
    transformations.inject(report) do |r,transformation|
      transformation.apply(r)
    end
    # report_format will always be the current format at this point, so we don't need it
    report.delete("report_format")
    report
  end
end

class ReportTransformer::ReportTransformation
  def self.apply(report)
    return report if report["report_format"] >= version

    transform(report)

    report["report_format"] = version
    report
  end
end

class ReportTransformer::ZeroToOne < ReportTransformer::ReportTransformation
  def self.version
    1
  end

  def self.transform(report)
    report["resource_statuses"] = []
    report
  end
end

class ReportTransformer::OneToTwo < ReportTransformer::ReportTransformation
  def self.version
    2
  end

  def self.transform(report)
    if report["metrics"] and report["metrics"]["time"] and !report["metrics"]["time"]["total"]
      report["metrics"]["time"]["total"] = report["metrics"]["time"].values.sum
    end

    report["status"] = failed_resources?(report) ? 'failed' : changed_resources?(report) ? 'changed' : 'unchanged'
    report
  end

  def self.failed_resources?(report)
    return true if report["metrics"].empty?
    (report["metrics"]["resources"] and report["metrics"]["resources"]["failed"] or 0) > 0
  end

  def self.changed_resources?(report)
    (report["metrics"] and report["metrics"]["changes"] and report["metrics"]["changes"]["total"] or 0) > 0
  end
end