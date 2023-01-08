/*==== aws_availability_zones ======*/
/*Gathering of AZs in the region. */

data "aws_availability_zones" "available" {
  state = "available"
}
