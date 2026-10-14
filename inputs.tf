module "record_inputs" {
  source = "./modules/record-inputs"

  records = {
    for key, record in var.records : key => merge(record, {
      content = try(tolist(record.content), [tostring(record.content)], null)
    })
  }
}
