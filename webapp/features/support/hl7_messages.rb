# Copyright (C) 2007, 2008, 2009 The Collaborative Software Foundation
#
# This file is part of TriSano.
#
# TriSano is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the
# Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# TriSano is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with TriSano. If not, see http://www.gnu.org/licenses/agpl-3.0.txt.

HL7MESSAGES = {}

def hl7_messages
  HL7MESSAGES
end

HL7MESSAGES[:arup_1] = <<ARUP1
MSH|^~\&|ARUP|ARUP LABORATORIES^46D0523979^CLIA|UTDOH|UT|200903261645||ORU^R01|200903261645128667|P|2.3.1|1\rPID|1||17744418^^^^MR||LIN^GENYAO^^^^^L||19840810|M||U^Unknown^HL70005|215 UNIVERSITY VLG^^SALT LAKE CITY^UT^84108^^M||^^PH^^^801^5854967|||||||||U^Unknown^HL70189\rORC||||||||||||^ROSENKOETTER^YUKI^K|||||||||University Hospital UT|50 North Medical Drive^^Salt Lake City^UT^84132^USA^B||^^^^^USA^B\rOBR|1||09078102377|13954-3^Hepatitis Be Antigen^LN|||200903191011|||||||200903191011|X|^ROSENKOETTER^YUKI^K||||||200903191011|||F||||||9^Unknown\rOBX|1|ST|13954-3^Hepatitis Be Antigen^LN|1|Positive||Negative||||F|||200903210007\r
ARUP1

HL7MESSAGES[:arup_2] = <<ARUP2
MSH|^~\&|ARUP|ARUP LABORATORIES^46D0523979^CLIA|UTDOH|UT|200903261645||ORU^R01|200903261645128673|P|2.3.1|1\rPID|1||16106551^^^^MR||WALLER^DAVID^E^^^^L||19620905|M||W^White^HL70005|3037 CURRENT CREEK DR^^SOUTH JORDAN^UT^84095^^M||^^PH^^^801^5669242|||||||||U^Unknown^HL70189\rORC||||||||||||^GLENN^MARTHA|||||||||University Hospital UT|50 North Medical Drive^^Salt Lake City^UT^84132^USA^B||^^^^^USA^B\rOBR|1||09078110757|5221-7^HIV-1 Antibody Confirm, Western Blot^LN|||200903191514|||||||200903191514|X|^GLENN^MARTHA|||||||||F||||||9^Unknown\rOBX|1|ST|5221-7^HIV-1 Antibody Confirm, Western Blot^LN|1|Positive||||||F|||200903211440\rOBX|2|CE|^Bordatella Per^LN||^See Note\r
ARUP2

HL7MESSAGES[:ihc_1] = <<IHC1
MSH|^~\&|RT-CEND|IHC-LD|||200902251217Z||ORU^R01||P|2.5\rPID|||362087||COVELL^DAREN^L||197010280000Z|M||W|3728 S 1925 W^^ROY^UT^840672804^USA||(801)731-7292\rPV1||I||||||||MED|||||||||112750906~948223|||||||||||||||||||||||||200902181810Z\rOBR|1|||NOTF|||||||||||||||||||||||||||""^SNM\rOBX|1|TM|00000-0^ALERT DATE^LN||200902250930Z\rOBX|2|PN|00000-0^PROVIDER NAME^LN||PETERSEN^FINN^B.\rOBX|3|TN|00000-0^PROVIDER PHONE^LN||8014081819\rOBX|4|NM|22025-1^PROVIDER ID^LN||02337\rOBX|5|ST|45403-3^ROOM NUMBER^LN||E820\rOBX|6|ST|42347-5^ADMIT DIAGNOSIS^LN||ALTERED MENTAL STATU\rOBX|7|TM|00000-0^PREVIOUS ADMIT DATE^LN||200811240953Z\rOBX|8|TM|00000-0^PREVIOUS DISCHARGE DATE^LN||200812261601Z\rOBX|9|ST|00000-0^CONTACT NAME^LN||Carrie Taylor\rOBX|10|TN|00000-0^CONTACT PHONE^LN||8015077782\rOBX|11|NM|21612-7^PATIENT AGE^LN||38\rOBR|2|186936||LABRPT||200902210950Z||||||||200902210956Z|&Bronchial Alveolar L||||||||||P\rOBX|1|CE|^Culture       ^LN||^""\r
IHC1

HL7MESSAGES[:no_msh] = <<NOMSH
PID|1||17744418^^^^MR||LIN^GENYAO^^^^^L||19840810|M||U^Unknown^HL70005|215 UNIVERSITY VLG^^SALT LAKE CITY^UT^84108^^M||^^PH^^^801^5854967|||||||||U^Unknown^HL70189\rORC||||||||||||^ROSENKOETTER^YUKI^K|||||||||University Hospital UT|50 North Medical Drive^^Salt Lake City^UT^84132^USA^B||^^^^^USA^B\rOBR|1||09078102377|13954-3^Hepatitis Be Antigen^LN|||200903191011|||||||200903191011|X|^ROSENKOETTER^YUKI^K||||||200903191011|||F||||||9^Unknown\rOBX|1|ST|13954-3^Hepatitis Be Antigen^LN|1|Positive||Negative||||F|||200903210007\r
ARUP1
NOMSH

HL7MESSAGES[:no_pid] = <<NOPID
MSH|^~\&|ARUP|ARUP LABORATORIES^46D0523979^CLIA|UTDOH|UT|200903261645||ORU^R01|200903261645128667|P|2.3.1|1\rORC||||||||||||^ROSENKOETTER^YUKI^K|||||||||University Hospital UT|50 North Medical Drive^^Salt Lake City^UT^84132^USA^B||^^^^^USA^B\rOBR|1||09078102377|13954-3^Hepatitis Be Antigen^LN|||200903191011|||||||200903191011|X|^ROSENKOETTER^YUKI^K||||||200903191011|||F||||||9^Unknown\rOBX|1|ST|13954-3^Hepatitis Be Antigen^LN|1|Positive||Negative||||F|||200903210007\r
NOPID

HL7MESSAGES[:no_obr] = <<NOOBR
MSH|^~\&|ARUP|ARUP LABORATORIES^46D0523979^CLIA|UTDOH|UT|200903261645||ORU^R01|200903261645128667|P|2.3.1|1\rPID|1||17744418^^^^MR||LIN^GENYAO^^^^^L||19840810|M||U^Unknown^HL70005|215 UNIVERSITY VLG^^SALT LAKE CITY^UT^84108^^M||^^PH^^^801^5854967|||||||||U^Unknown^HL70189\rORC||||||||||||^ROSENKOETTER^YUKI^K|||||||||University Hospital UT|50 North Medical Drive^^Salt Lake City^UT^84132^USA^B||^^^^^USA^B\rOBX|1|ST|13954-3^Hepatitis Be Antigen^LN|1|Positive||Negative||||F|||200903210007\r
NOOBR

HL7MESSAGES[:no_obx] = <<NOOBX
MSH|^~\&|ARUP|ARUP LABORATORIES^46D0523979^CLIA|UTDOH|UT|200903261645||ORU^R01|200903261645128667|P|2.3.1|1\rPID|1||17744418^^^^MR||LIN^GENYAO^^^^^L||19840810|M||U^Unknown^HL70005|215 UNIVERSITY VLG^^SALT LAKE CITY^UT^84108^^M||^^PH^^^801^5854967|||||||||U^Unknown^HL70189\rORC||||||||||||^ROSENKOETTER^YUKI^K|||||||||University Hospital UT|50 North Medical Drive^^Salt Lake City^UT^84132^USA^B||^^^^^USA^B\rOBR|1||09078102377|13954-3^Hepatitis Be Antigen^LN|||200903191011|||||||200903191011|X|^ROSENKOETTER^YUKI^K||||||200903191011|||F||||||9^Unknown\r
NOOBX
