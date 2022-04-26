#!/usr/bin/perl

use open qw( :encoding(UTF-8) :std );
use strict;
use JSON;
use Net::LDAP;
use Net::LDAPS;
use Net::LDAP::LDIF;
use XML::LibXML;
use Data::Dumper;
use File::Basename;
use Getopt::Std;
use Class::Date qw(:errors date localdate gmdate now -DateParse);
use YAML qw'LoadFile';
$Class::Date::DATE_FORMAT="%Y-%m-%d";

my $prgname = basename($0);

my $doc = XML::LibXML::Document->new('1.0', 'UTF-8'); 	# global

sub usage {
  my $msg = shift;
  $msg and $msg = " ($msg)";
  return "usage: $prgname -o out_base -c config_file (or -e expiredate (yyyymmdd) -s select_term(s), comma-separated) [-u cutoff_date (yyyymmdd) -t (use test server) $msg\n";
}

my $today = substr(getDate(), 0, 8);
my $today_date = date(join('-', substr($today,0,4), substr($today,4,2), substr($today,6,2)));

our ($opt_o, $opt_c, $opt_e, $opt_s, $opt_t, $opt_u);
my $term_string;
my $expire_st;
getopts('o:c:e:s:u:t');
$opt_o or die usage("no output base specified");
if ($opt_c) {
  my $config_file = $opt_c;
  my $config = LoadFile($config_file) or die "can't load yaml config file $config_file: $!\n";
  my $config_date_used;
  CONFIG:foreach my $config_date (sort keys %$config) {
    $config_date >= $today and do {
      $term_string = $config->{$config_date}->{terms};
      $expire_st = $config->{$config_date}->{expire_date};
      $config_date_used = $config_date; 
      last CONFIG;
    };
  }
  $expire_st and $term_string or die "can't get current config from config file $config_file\n";
  $config_date_used == 99999999 and die "*** warning: using last entry from $config_file\n";
  print "using config file for terms and student expire date, config date: $config_date_used, term string: $term_string, student expire date : $expire_st\n";
  #print Dumper $config;
} else {
  $opt_e or die usage("no student expire date specified");
  $opt_s or die usage("no student terms specified");
  $expire_st = $opt_e;
  $term_string = $opt_s;
}

my $outbase = $opt_o;
my $select_terms = {};
foreach my $term (split(/[,\s]+/,  $term_string)) {
  $term =~ /^[WSF]{1}[SPU]{0,1}[0-9]{2}$/ or die usage("invalid term $term specified: $opt_s");
  $select_terms->{$term}++;
}
my $select_term_list = join(",", sort keys %$select_terms);

$expire_st =~ /^\d{8}$/ or die usage("invalid student expire date $expire_st");
my $expire_date_st = date(join('-', substr($expire_st,0,4), substr($expire_st,4,2), substr($expire_st,6,2)));
my $purge_date_st = $expire_date_st + '2Y';

# expire for fac/staff is greater of student expire date or current date plus 56 days, purge is 2 years after that
#my $expire_date_fs = $today_date + '90D';
my $expire_offset = $today_date + '56D';

my $expire_date_fs = $expire_offset > $expire_date_st ? $expire_offset : $expire_date_st;
my $purge_date_fs = $expire_date_fs + '2Y';

my $date_cutoff = 0;
my $date_cutoff_utc;
$opt_u and do {
  $opt_u =~ /^\d{8}$/ or die usage("invalid created cutoff date: $opt_u");
  $date_cutoff = $opt_u;
  local $Class::Date::DATE_FORMAT="%Y%m%d%H%M%S";
  $date_cutoff_utc = Class::Date->new($date_cutoff . '000000','EST')->to_tz('GMT') . '.0Z';
  #$date_cutoff_utc = $date_cutoff . '000000.0Z'; 
  print "date_cutoff set: extracting patrons created/modified after $date_cutoff ($date_cutoff_utc)\n";
  print STDERR "date_cutoff set: extracting patrons created/modified after $date_cutoff ($date_cutoff_utc)\n";
};
my $file_size = 5000;
my $num_output_files = 0;
my @output_files = ();

sub open_new_output_file {
  $num_output_files and do {
    print OUTXML "</users>\n";
    close OUTXML;
  };
  $num_output_files++;
  my $filename = sprintf("%s_%03d.xml", $outbase, $num_output_files);
  open(OUTXML, ">$filename") or die "can't open $filename for output: $!\n";
  push @output_files, $filename;
  print OUTXML '<?xml version="1.0"?>', "\n";
  print OUTXML "<users>\n";
}

open(OUTXML_ERR, ">${outbase}_error.xml") or die "can't open ${outbase}_error.xml for output: $!\n";
open(OUTRPT, ">${outbase}_rpt.txt") or die "can't open ${outbase}_rpt.txt for output: $!\n";

my $NULLCHAR = "%";
my $ACTION = "A";
my $DEFAULT_Z305_SUB_LIBRARY = "MIU50";

my $attrs =  [
  'createtimestamp',
  'modifytimestamp',
  'displayName',
  'umichDisplaySn',
  'umichDisplayMiddle',
  'givenName',
  'homePhone',
  'mobile',
  'telephoneNumber',
  'umichPermanentPhone',
  'mail',
  'umichInstRoles',
  'umichAAAcadProgram',
  'umichAATermStatus',
  'umichDbrnCurrentTermStatus',
  'umichDbrnTermStatus',
  'umichFlntCurrentTermStatus',
  'umichFlntTermStatus',
  'umichHR',
  'umichSponsorshipDetail',
  'entityid',
  'uid',
  'umichScholarId',
  #'postalAddress',
  'umichHomePostalAddressData',
  'umichPermanentPostalAddressData',
  'umichPostalAddressData',
  #'umichHomePostalAddress',
  #'umichPermanentPostalAddress',
  #'umichPostalAddress',
]; 

my %term_map = (
  "UMAA" => {
    "222" => "W19",
    "223" => "SP19",
    "224" => "SS19",
    "225" => "SU19",
    "226" => "F19",
    "227" => "W20",
    "228" => "SP20",
    "229" => "SS20",
    "230" => "SU20",
    "231" => "F20",
    "232" => "W21",
    "233" => "SP21",
    "234" => "SS21",
    "235" => "SU21",
    "236" => "F21",
    "237" => "W22",
    "238" => "SP22",
    "239" => "SS22",
    "240" => "SU22",
    "241" => "F22",
    "242" => "W23",
    "243" => "SP23",
    "244" => "SS23",
    "245" => "SU23",
    "246" => "F23",
    "247" => "W24",
    "248" => "SP24",
    "249" => "SS24",
    "250" => "SU24",
    "251" => "F24",
  },
  "UMFL" => {
    "201910" => "F18",
    "201920" => "W19",
    "201930" => "SP19",
    "201940" => "SU19",
    "202010" => "F19",
    "202020" => "W20",
    "202030" => "SP20",
    "202040" => "SU20",
    "202110" => "F20",
    "202120" => "W21",
    "202130" => "SP21",
    "202140" => "SU21",
    "202210" => "F21",
    "202220" => "W22",
    "202230" => "SP22",
    "202240" => "SU22",
    "202310" => "F22",
    "202320" => "W23",
    "202330" => "SP23",
    "202340" => "SU23",
    "202410" => "F23",
    "202420" => "W24",
    "202430" => "SP24",
    "202440" => "SU24",
  },
  "UMDB" => {
    "201910" => "F18",
    "201920" => "W19",
    "201930" => "SP19",
    "201940" => "SU19",
    "202010" => "F19",
    "202020" => "W20",
    "202030" => "SP20",
    "202040" => "SU20",
    "202110" => "F20",
    "202120" => "W21",
    "202130" => "SP21",
    "202140" => "SU21",
    "202210" => "F21",
    "202220" => "W22",
    "202230" => "SP22",
    "202240" => "SU22",
    "202310" => "F22",
    "202320" => "W23",
    "202330" => "SP23",
    "202340" => "SU23",
    "202410" => "F23",
    "202420" => "W24",
    "202430" => "SP24",
    "202440" => "SU24",
  },
);

my %term_map_min = ();
# get the minimum term value foreach campus
foreach my $campus (keys %term_map) {
  my @term_list = sort keys %{$term_map{$campus}};
  my $min_term = shift @term_list;
  $term_map_min{$campus} = $min_term;
}

my %campus_map = (
  'aa' => 'UMAA',
  'dbrn' => 'UMDB',
  'flnt' => 'UMFL',
  'um_ann-arbor' => 'UMAA',
  'um_flint' => 'UMFL',
  'um_dearborn' => 'UMDB',
);

my %role_to_bstat_btype = (	
  'faculty' => ['01','FA'],
  'regularstaff' => ['02','ST'],
  'temporarystaff' => ['14','TS'],
  'staff' => ['02','ST'],
  'sponsoredaffiliate' => ['01','SA'],
  'retiree' => ['01','RF'],
);

my %classStanding_to_bstat_btype = (	# map Flint/Dearborn class standing to borrower type
  'FR' => ['04','UN'],
  'SO' => ['04','UN'],
  'JR' => ['04','UN'],
  'SR' => ['04','UN'],
  'UN' => ['04','UN'],
  'UC' => ['04','UN'],
  'EP' => ['04','UN'],
  'PC' => ['04','UN'],
  'GR' => ['03','GR'],
  'DO' => ['03','GR'],
  'SP' => ['03','GR'],
  'PN' => ['03','GR'],
);

my %aa_pcode_prog_to_bstat_btype = (
  'U' => ['04','UN'],
  'G' => ['03','GR'],
  'GRAC' => ['03','CD'],
  'P' => ['03','GR'],
  'A01363' => ['04','UN'],
  'A01364' => ['03','GR'],
  'A01365' => ['04','UN'],
  'A01366' => ['03','GR'],
  'A01367' => ['04','UN'],
  'A01368' => ['03','GR'],
  'A02059' => ['04','UN'],
  'A02106' => ['04','UN'],
  'A02116' => ['03','GR'],
  'A02125' => ['03','GR'],
  'A02114' => ['03','GR'],
  'A02096' => ['03','GR'],
  'A02096' => ['03','GR'],
  'A02114' => ['03','GR'],
  'A02096' => ['03','GR'],
);

#  $bstat ne '01' and $jobcode =~/^(205000|205800|205400|209010)$/ and do {
#    print "$reccnt ($FILETYPE), $emplid--bstat changed from $bstat to 01 for jobcode=$jobcode\n";
#    $bstat = '01';
#  };
my %jobcode_to_btype = (
  "110370" => "AF",     # ADJUNCT CLINICAL ASSOCIATE
  "128830" => "AF",     # ADJUNCT FACULTY ASSOCIATE
  "128890" => "AF",     # ADJUNCT ASST RES SCI
  "128980" => "AF",     # ADJUNCT ASSOC RES SCI
  "128990" => "AF",     # ADJUNCT RES SCIENTIST
  "129030" => "AF",     # ADJUNCT RES INVESTIGATOR
  "129050" => "AF",     # ADJUNCT CURATOR
  "129060" => "AF",     # ADJUNCT ASSOC CURATOR
  "129070" => "AF",     # ADJUNCT ASST CURATOR
  "201030" => "AF",     # ADJUNCT PROFESSOR
  "201040" => "AF",     # ADJUNCT CLINICAL PROFESSOR
  "201530" => "AF",     # ADJUNCT ASSOC PROFESSOR
  "201540" => "AF",     # ADJUNCT CLIN ASSOC PROF
  "202030" => "AF",     # ADJUNCT ASST PROFESSOR
  "202040" => "AF",     # ADJUNCT CLIN ASST PROFESSOR
  "202530" => "AF",     # ADJUNCT INSTRUCTOR
  "202540" => "AF",     # ADJUNCT CLINICAL INSTRUCTOR
  "203030" => "AF",     # ADJUNCT LECTURER
  "203040" => "AF",     # ADJUNCT CLINICAL LECTURER
  "103040" => "EM",     # DEAN EMERITUS/A
  "129510" => "EM",     # SR RES SCIENTIST EMERITUS
  "201070" => "EM",     # PROFESSOR EMERITUS/A
  "201110" => "EM",     # ASSOC PROF EMERITUS/A
  "201120" => "EM",     # ASST PROF EMERITUS/A
  "205000" => "GE",     # GRAD STU INSTR
  "205400" => "GE",     # GRAD STU RES ASST
  "205800" => "GE",     # GRAD STU STAFF ASST
);


# ldap config
my $ldap_config_file = "mcommunity_ldap_config.yaml";
my $ldap_config = LoadFile($ldap_config_file) or die "can't load yaml ldap config file $ldap_config_file: $!\n";

my $bind_dn = 'cn=LIT-MCDirApp001,ou=Applications,o=services';
my $bind_pw = 'password';		# production
my $ldap_host = 'host';	# production (no-limit)

my $ldap_sys = 'prod';
$opt_t and do {
  $ldap_sys = 'test';
  print STDERR "querying QA ldap server ($ldap_config->{$ldap_sys}->{ldap_host})\n";
};

my $mcommunity = Net::LDAP->new("ldaps://$ldap_config->{$ldap_sys}->{ldap_host}") or die $@;

my $bind_mesg;
$bind_mesg = $mcommunity->bind($ldap_config->{$ldap_sys}->{bind_dn}, 'password' => $ldap_config->{$ldap_sys}->{bind_pw});

$bind_mesg->code and do {
  LDAPerror("bind", $bind_mesg);
  die;
};

my $filter = "(|(" . join(') (', 
  "umichInstRoles=EnrolledStudentDBRN", 
  "umichInstRoles=StudentFLNT", 
  "umichInstRoles=StudentAA", 
  "umichInstRoles=Faculty*", 
  "umichInstRoles=RegularStaff*",
  "umichInstRoles=TemporaryStaffAA",
  "umichInstRoles=SponsoredAffiliateAA",
  "umichInstRoles=Retiree",
  ) .  ') )';

$date_cutoff and do {
 $filter = "(& $filter (| (modifyTimeStamp>=$date_cutoff_utc) (createTimeStamp>=$date_cutoff_utc)) )";
};

print STDERR "query filter: $filter\n";

my $res = $mcommunity->search(
  'base' => 'ou=People,dc=umich,dc=edu', 
  'scope' => 'sub', 
  'objectclass' => '*', 
  'filter' => $filter,
#  'filter' => 'uid=pjbarrow',
#  'filter' => 'uid=pav',
  'attrs' => $attrs,
);

my $patron_id;
my $output_count = {};
my %role_count = ();
my %addr_count = ();
my %counters = ();
my %allSponsorReasons = ();
my %selectedSponsorReasons = ();
my %departments = ();
my %academic_programs = ();

print OUTXML_ERR '<?xml version="1.0"?>', "\n";
print OUTXML_ERR "<users>\n";
ENTRY:foreach my $entry ( $res->entries ) {
  #dump_entry($entry);
  #next;
  $counters{'ldap entries processed'}++;
  my $info = {};
  
  $info->{umid} = $entry->get_value('entityid');
  $info->{umid} =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing whitespace
  $info->{match_id} = $info->{umid};
  $info->{uniqname} = $entry->get_value('uid');
  $info->{uniqname} =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing whitespace
  #$info->{fullname} = $entry->get_value('displayName');
  $patron_id = "$info->{umid} ($info->{uniqname})"; 	# for messages
  $info->{uniqname} =~ /ststv/ and do {
    print OUTRPT "$patron_id: test patron excluded\n";
    next ENTRY;
  };
  my $entry_create_timestamp = substr($entry->get_value('createtimestamp'),0,8);
  my $entry_modify_timestamp = substr($entry->get_value('modifytimestamp'),0,8);
  ($entry_create_timestamp >= $date_cutoff or $entry_modify_timestamp >= $date_cutoff) or do {
    $counters{'ldap create/update date less than cutoff'}++;
    next ENTRY;
  };
  $info->{email} = $entry->get_value('mail');
  $info->{telephoneNumber} = $entry->get_value('telephoneNumber');
  $info->{all_roles} = join(",", $entry->get_value('umichInstRoles'));
  getInstRole($info, $entry) or do {
    print OUTRPT "$patron_id: no valid role found, role list is '",  $info->{all_roles}, "'\n";
    $counters{"no valid role"}++;
    next ENTRY;
  };
  processName($info, $entry) or do {
    print OUTRPT "$patron_id: can't process name, record ignored\n";
    $counters{"can't process name"}++;
    next ENTRY;
  };
  $info->{firstname} and $info->{lastname} or do {
    print OUTRPT "$patron_id: firstname or lastname not set\n";
    print "$patron_id: firstname or lastname not set\n";
    dump_entry($entry);
  };

  $info->{btype} or do {
    print OUTRPT "$patron_id: btype not set\n";
    dump_entry($entry);
  };
  setJobDescription($info);
  my $write_to_errfile = 0;

  my $user = $doc->createElement('user');

  addUserInfo($info, $user); 
  addUserStatistics($info, $user);
  addUserRoles($info, $user);
  addContactInfo($info, $user, $entry);
  addUserIdentifiers($info, $user);

  $output_count->{instRole}->{$info->{instRole}}++;
  $output_count->{campus}->{$info->{campus}}++;
  $output_count->{bstat}->{$info->{bstat}}++;
  $output_count->{btype}->{$info->{btype}}++;

  if ($write_to_errfile) {
#    print OUTXML_ERR XMLout($record,  
#      RootName => 'user',
#      #KeyAttr => 'user',
#      #ForceArray => ['address_types'],
#      ForceArray => 1,
#      #NoAttr => 1,
#    );
    $counters{'xml records written to xml error file'}++;
  } else {
    $counters{'xml records written to xml load file'} % $file_size == 0 and open_new_output_file();
    print OUTXML $user->toString(1), "\n";
    $counters{'xml records written to xml load file'}++;
  }
 
  $info->{'acadProg'} and $info->{'acadProgDescr'} and do {
    $academic_programs{join("\t",  $info->{'acadProg'}, $info->{'acadProgDescr'})}++;
  };
  $info->{'deptId'} and $info->{'deptDescription'} and do {
    $departments{join("\t",  $info->{'deptId'}, $info->{'deptDescription'})}++;
  };

  print OUTRPT join("\t", 
    "LOAD",
    $info->{umid},
    $info->{firstname},
    $info->{lastname},
    $info->{middlename},
    $info->{uniqname},
    $info->{campus}, 
    $info->{job_description}, 
    $info->{budget}, 
    $info->{bstat}, 
    $info->{btype}, 
    $info->{jobcode},
    $info->{instRole},
    $info->{sponsorReason},
    $info->{all_roles},
    Class::Date->new(substr($entry->get_value('createtimestamp'), 0, 14),'GMT')->to_tz('EST'),
    Class::Date->new(substr($entry->get_value('modifytimestamp'), 0, 14),'GMT')->to_tz('EST'),
    $info->{expire_date},
    #$info->{regStatus},
    #$info->{fullname_lastfirst},
    #$info->{fullname},
  ), "\n";

  #dump_entry($entry);
  
}
print OUTXML "</users>\n";
print OUTXML_ERR "</users>\n";

foreach my $counter ('ldap entries processed', 'xml records written to xml load file') {
  print "$counter: $counters{$counter}\n";
}
print OUTRPT "\nfilter is $filter\n";
print OUTRPT "Total entries found: ", $res->count, "\n";
print OUTRPT "\n";
print OUTRPT "Student terms: $select_term_list\n";
print OUTRPT "Default student expire date: $expire_st\n";;
print OUTRPT "\n";
foreach my $counter (sort keys %counters) {
  print OUTRPT "$counter: $counters{$counter}\n";
}

print OUTRPT "\nall sponsor reasons\n";
foreach my $reason (sort keys %allSponsorReasons) {
  print OUTRPT "$reason: $allSponsorReasons{$reason}\n";
}

print OUTRPT "\nselected sponsor reasons\n";
foreach my $reason (sort keys %selectedSponsorReasons) {
  print OUTRPT "$reason: $selectedSponsorReasons{$reason}\n";
}

foreach my $type ("instRole", "campus", "bstat", "btype") {
  print OUTRPT "\n$type\n";
  foreach my $key (sort keys %{$output_count->{$type}}) {
    print OUTRPT "$key: $output_count->{$type}->{$key}\n";
  }
}
print OUTRPT "Output files:\n", join("\n\t", @output_files), "\n";

# output list of department codes and their descriptions
#open (DEPT, ">${outbase}_dept_list.txt") or die "can't open ${outbase}_dept_list.txt for output: $!\n";
#foreach my $dept (sort keys %departments) {
#  print DEPT "$dept\t$departments{$dept}\n";
#}
#close DEPT;

# output list of academic program codes and their descriptions
#open (ACAD, ">${outbase}_acadprog_list.txt") or die "can't open ${outbase}_acadprog_list.txt for output: $!\n";
#foreach my $acad_prog (sort keys %academic_programs) {
#  print ACAD "$acad_prog\t$academic_programs{$acad_prog}\n";
#}
#close ACAD;

sub setJobDescription {
  my $info = shift;

  SET_DESC: {
    $info->{btype} =~ /(FA|ST|VS|TS|GE|EM|AF)/ and do {
      $info->{job_description} = $info->{deptDescription};
      last SET_DESC;
    };
    $info->{btype} =~ /(GR|UN|CD)/ and do {
      if ($info->{campus} eq 'UMAA') {
        $info->{job_description} = $info->{acadProgDescr};
      } else {		# UMDB or UMFL
        $info->{job_description} = $info->{programDesc};
      }
      last SET_DESC;
    };
    $info->{btype} =~ /(SA|CN|RF)/ and do {
      $info->{job_description} = $info->{deptDescription};
      last SET_DESC;
    };
    print join("\t", "NOT_SET", $patron_id, $info->{btype}, $info->{campus}, $info->{instRole}, $info->{deptDescription}), "\n";
    return 0;
  }
  return 1;
}
  
sub addChild {
  my $parent = shift;
  my $name = shift;
  my $value = shift;
  my $attr_list = shift;

  my $tag = $doc->createElement($name);
  $attr_list and do {
    foreach my $attr (@$attr_list) {
      $tag->setAttribute($attr->{'name'}, $attr->{'value'});
    }
  };
  $tag->appendTextNode($value);
  $parent->appendChild($tag);
}

sub addUserInfo {
  my $info = shift;
  my $user = shift;
  $info->{budget} or do {
    print STDERR "$patron_id: no budget\n";
  };
  addChild($user, 'record_type', 'PUBLIC');
  addChild($user, 'external_id', 'SIS');
  addChild($user, 'primary_id', $info->{uniqname});
  defined $info->{'firstname'} and addChild($user, 'first_name', $info->{firstname});
  defined $info->{'middlename'} and addChild($user, 'middle_name', $info->{middlename});
  defined $info->{'lastname'} and addChild($user, 'last_name', $info->{lastname});
  addChild($user, 'campus_code', $info->{campus});
  addChild($user, 'user_group', $info->{bstat});
  addChild($user, 'status',  'ACTIVE');	# desc="Active"
  addChild($user, 'status_date', $today_date->string);	# desc="Active"
  defined $info->{expire_date} and defined $info->{purge_date} or do {
    print Dumper $info;
    die "$patron_id: expire_date/purge_date not defined\n";
  };
  addChild($user, 'expiry_date', $info->{expire_date}->string);
  addChild($user, 'purge_date', $info->{purge_date}->string);
  addChild($user, 'job_description', $info->{job_description});
  return 1;
}

sub addUserStatistics {
  my $info = shift;
  my $user = shift;
  my $user_statistics = $doc->createElement('user_statistics');
  my $user_statistic = $doc->createElement('user_statistic');
  addChild($user_statistic, 'statistic_category', $info->{'btype'});
  $user_statistics->appendChild($user_statistic);
  $user->appendChild($user_statistics);
  return 1;
}

sub addUserRoles {
  my $info = shift;
  my $user = shift;
  my $user_roles = $doc->createElement('user_roles');
  my $user_role = $doc->createElement('user_role');
  addChild($user_role, 'status' , 'ACTIVE');
  addChild($user_role, 'scope', '01UMICH_INST');
  addChild($user_role, 'role_type', '200');
  $user_roles->appendChild($user_role);
  $user->appendChild($user_roles);
  return 1;
}

sub addUserIdentifiers {
  my $info = shift;
  my $user = shift;

  my $user_identifiers = $doc->createElement('user_identifiers');
  my $user_identifier;

  # UMID
  $user_identifier = $doc->createElement('user_identifier');
  addChild($user_identifier, 'id_type' , '02');
  addChild($user_identifier, 'value', $info->{umid});
  addChild($user_identifier, 'status', 'Active');
  $user_identifiers->appendChild($user_identifier);

  # Inst ID (uniqname@umich.edu, for SAML auth)
  $user_identifier = $doc->createElement('user_identifier');
  addChild($user_identifier, 'id_type' , '05');
  addChild($user_identifier, 'value', $info->{uniqname} . '@umich.edu');
  addChild($user_identifier, 'status', 'Active');
  $user_identifiers->appendChild($user_identifier);

  $user->appendChild($user_identifiers);
  return 1;
}

sub addContactInfo {
  my $info = shift;
  my $user = shift;
  my $entry = shift;

  my $contact_info = $doc->createElement('contact_info');

  addAddresses($info, $entry, $contact_info);
  addEmails($info, $contact_info);
  addPhones($info, $contact_info, $entry) or $counters{"no phone number"}++;;

  $user->appendChild($contact_info);
  return 1;
}
  
sub addEmails {
  my $info = shift;
  my $parent = shift;

  my $emails = $doc->createElement('emails');

  #my $email = $doc->createElement('email');
  my $email = $doc->createElement('email');
  $email->setAttribute('preferred', 'true');
  my $email_addr = $info->{email};
  #$email_addr =~ s/\@/\@SCRUBBED_/;
  addChild($email, 'email_address' , $email_addr);

  my $email_types = $doc->createElement('email_types');
  my $email_type = 'school';
  $info->{bstat} =~ /^(01|02|14)/ and $email_type = 'work';
  addChild($email_types, 'email_type' , $email_type);

  $email->appendChild($email_types);
  $emails->appendChild($email);
  $parent->appendChild($emails);
  return 1;
}

sub addPhones {
  my $info = shift;
  my $parent = shift;
  my $entry = shift;

  my $phoneNumber = '';
  foreach my $attr ( 'telephoneNumber', 'umichPermanentPhone') {
    $phoneNumber = $entry->get_value($attr) and last;
  }

  my $phones = $doc->createElement('phones');

  $phoneNumber and do {
    my $phone = $doc->createElement('phone');
    addChild($phone, 'phone_number' , $phoneNumber);
    $phone->setAttribute('preferred', 'true');
    # defaulting to home--there may be other phone types in mcommunity
    # Alma phone types are home, mobile, office, and office_fax
    my $phone_type = 'home';
    #$info->{bstat} =~ /^(01|02|14)/ and $phone_type = 'work';
    my $phone_types = $doc->createElement('phone_types');
    addChild($phone_types, 'phone_type' , $phone_type);
    $phone->appendChild($phone_types);
    $phones->appendChild($phone);
  };

  $parent->appendChild($phones);
  return 1;
}

sub addAddresses {
  my $info = shift;
  my $entry = shift;
  my $parent = shift;

  my $addresses = $doc->createElement('addresses');
    
  my @types = ();
  my $preferred = 'true'; # first one we add will be preferred
  # school/work address
  foreach my $addr_attr ( 'umichPostalAddressData', 'umichHomePostalAddressData') {
    my $address = $doc->createElement('address');
    my $address_data;
    $address_data = $entry->get_value($addr_attr) and do {
      my $address_type = 'school';
      $info->{bstat} =~ /^(01|02|14)/ and $address_type = 'work';
      addAddress($addresses, parseField($address_data), $address_type, $preferred);
      $preferred = 'false';  # set for subsequent addresses
      push @types, $address_type;
      last;
    };
  }
  # permanent address
  foreach my $addr_attr ( 'umichPermanentPostalAddressData', 'umichHomePostalAddressData') {
    my $address = $doc->createElement('address');
    my $address_data;
    $address_data = $entry->get_value($addr_attr) and do {
      addAddress($addresses, parseField($address_data), 'home', $preferred);
      $preferred = 'false';  # set for subsequent addresses
      push @types, 'home';
      last;
    };
  }
  $parent->appendChild($addresses);

  return 1;
}

sub addAddress {
  my $parent = shift;
  my $data = shift;
  my $type = shift;
  my $preferred = shift;

  $data->{'addr1'} or do {
    $data->{'addr1'} = '(no address)';
    $counters{"Default addr1 used"}++;
  };
 
  my $address_field_map = {
    'addr1' => 'line1',
    'addr2' => 'line2',
    'city' => 'city',
    'state' => 'state_province',
    'postal' => 'postal_code',
    'nation' => 'country',
    #'nationCode' => '',
  };
  my $address = $doc->createElement('address');
  $address->setAttribute('preferred', $preferred);
  foreach my $ldap_tag (sort keys %$address_field_map) {
    my $alma_tag = $address_field_map->{$ldap_tag};
    $alma_tag or next;
    defined $data->{$ldap_tag} and addChild($address, $alma_tag, $data->{$ldap_tag});
  }
  my $address_types = $doc->createElement('address_types');
  addChild($address_types, "address_type", $type);
  $address->appendChild($address_types);
  $parent->appendChild($address);
  return 1;
}  

sub keepSponsoredAffiliateRole {
  my $role = shift;
  my $info = shift;
  my $entry = shift;
  
#umichSponsorStartDate=01/23/2014}:{umichSponsorEndDate=01/03/2017

  my $select_sponsor_reasons = {
    'Associates' => 0,
    'Contractors' => 1,
    'Faculty' => 1,
    'Other Guests' => 0,
    'PC Participants' => 0,
    'Researchers' => 1,
    'Subscribers' => 0,
    'Temporary Staff' => 1,
    'Wireless Users' => 0,
    'Affiliates' => 1,
  };
  #print "checking sponsorship detail for $patron_id\n";
  my @sponsor_reasons_list = ();
  my $active_date = 0;
  my $sponsor_expire_date = 0;
  USD:foreach my $usd ($entry->get_value('umichSponsorshipDetail')) {
    my $usd_data = parseField($usd);
    my $start_date = $usd_data->{umichSponsorStartDate} or do {
      print OUTRPT "$patron_id: no sponsor start date\n";
      next USD;
    };
    $start_date = parseDate($start_date) or do {
      print OUTRPT "$patron_id: invalid format for sponsor start date: $start_date\n";
      next USD;
    };
    my $end_date = $usd_data->{umichSponsorEndDate} or do {
      print OUTRPT "$patron_id: no sponsor end date\n";
      next USD;
    };
    $end_date = parseDate($end_date) or do {
      print OUTRPT "$patron_id: invalid format for sponsor end date: $end_date\n";
      next USD;
    };
    $start_date <= $today_date and $end_date > $today_date or do {
      print OUTRPT "$patron_id: sponsor dates not active: start $start_date end $end_date\n";
      next USD;
    };
    $active_date++;
    $end_date > $sponsor_expire_date and $sponsor_expire_date = $end_date;
    my $sponsorReason = $usd_data->{umichSponsorReason};
    $allSponsorReasons{$sponsorReason}++;
    push @sponsor_reasons_list, $sponsorReason;
    $usd_data->{deptDescription} =~ /LSA UG: UROP/i and do {
      print OUTRPT "$patron_id: urop sponsored affiliate excluded ($usd_data->{deptDescription}), sponsorReason is $sponsorReason\n";
      next USD;
    };
    #$sponsorReason eq 'Affiliates' and $usd_data->{deptId} eq '309911' and do {
    #  print OUTRPT "$patron_id: sponsored affiliate excluded for deptID 309911,  deptDescription is $usd_data->{deptDescription}, sponsorReason is $sponsorReason\n";
    #  next USD;
    #};
    $select_sponsor_reasons->{$sponsorReason} and do {
      $selectedSponsorReasons{$sponsorReason}++;
      print OUTRPT "$patron_id: sponsored affiliate included,  deptDescription is $usd_data->{deptDescription} ($usd_data->{deptId}), sponsorReason is $sponsorReason\n";
      $info->{sponsorReason} = $sponsorReason;
      return 1;
    };
  }
  $active_date or return 0;
  $info->{expire_date} = $expire_date_fs;
  $info->{purge_date} = $purge_date_fs;
  $sponsor_expire_date and $sponsor_expire_date < $info->{expire_date} and do {
    $info->{expire_date} = $sponsor_expire_date;
    $info->{purge_date} = $sponsor_expire_date + '2Y';
  };

  # no valid sponsor reason, check role
  $info->{all_roles} =~ /(newhire|temporarystaffaa)/i and do {
    my $selected_sponsor_role = $1;
    $info->{sponsorReason} = $selected_sponsor_role;
    $selectedSponsorReasons{"role: $selected_sponsor_role"}++;
    print OUTRPT join("\t", 
        $patron_id, 
        "sponsor selected based on role",
        $role, 
        join(", ", @sponsor_reasons_list), 
        $info->{sponsorReason},
        $info->{ldap_campus},
        $info->{campus},
        $info->{all_roles},
    ),"\n";
    return 1;
  };
  print OUTRPT join("\t", 
      $patron_id, 
      "sponsor not selected",
      $role, 
      join(", ", @sponsor_reasons_list), 
      $info->{ldap_campus},
      $info->{campus},
      $info->{all_roles},
  ),"\n";
  return 0;
}

sub parseDate {
  my $date = shift;
  my ($month, $day, $year) = $date =~ /^(\d{2})\/(\d{2})\/(\d{4})$/ or return '';
  return date {year => $year, month => $month, day => $day};
  #return sprintf("%04d%02d%02d", $year, $month, $day);
}

sub getInstRole {
  my $info = shift;
  my $entry = shift;

  my $all_roles = $entry->get_value('umichInstRoles', asref => 1);
  my @role_list = (
    "^(Faculty)(AA)\$",
    "^(RegularStaff)(AA)\$",
    "^Enrolled(Student)(AA)\$",
    "(Student)(AA)\$",
    "^(SponsoredAffiliate)(AA)\$",
    "^(Faculty)(FLNT)\$",
    "^(RegularStaff)(FLNT)\$",
    "^Enrolled(Student)(FLNT)\$",
    "(Student)(FLNT)\$",
    "^(Faculty)(DBRN)\$",
    "^(RegularStaff)(DBRN)\$",
    "^Enrolled(Student)(DBRN)\$",
    #"^(SponsoredAffiliate)(FLNT)\$",
    #"^(SponsoredAffiliate)(DBRN)\$",
    "^(TemporaryStaff)(AA)\$",
    "^(Retiree)\$",
  );
  foreach my $role_pattern (@role_list) {
    INST_ROLE:foreach my $inst_role (@$all_roles) {
      $inst_role =~ s/^\s*(.*?)\s*$/$1/;    # trim leading and trailing whitespace
      $inst_role =~ /$role_pattern/i and do {
        $info->{instRole} = lc($1);
        $2 and do {
          $info->{ldap_campus} = $2;
          $info->{campus} = $campus_map{lc($info->{ldap_campus})};
        };
        $info->{instRole} =~ /^(faculty|regularstaff|temporarystaff|sponsoredaffiliate|retiree)$/ and do {
          $info->{expire_date} = $expire_date_fs;
          $info->{purge_date} = $purge_date_fs;
          $info->{instRole} =~ /^sponsoredaffiliate/i and do {
            keepSponsoredAffiliateRole($info->{instRole}, $info, $entry) or next INST_ROLE;
          };
          processHRinfo($info, $entry) or do {
            print OUTRPT "$patron_id: no valid HR info for role $info->{instRole}\n";
            $counters{"entry ignored: no valid info for $info->{instRole}"}++;
            next INST_ROLE;
          };
          return 1;
        };
        $info->{instRole} =~ /^(student)$/ and do {
          processStudentInfo($info, $entry, $select_terms) or do {
            print OUTRPT "$patron_id: no valid student info for role $info->{instRole}\n";
            $counters{"entry ignored: no valid info for $info->{instRole}"}++;
            next INST_ROLE;
          };
          return 1;
        };
        print OUTRPT "$inst_role $info->{instRole}\n";
        print STDERR "$inst_role $info->{instRole}\n";
        return 0;
      };
    }
  }  
  return 0;
}

sub getHRdata {
  my $info = shift;
  my $entry = shift;
  my $attr = shift;

  my $hr_list = $entry->get_value($attr, asref => 1);
  $hr_list or do { # no hr data for supplied attr: if it's faculty, check for sponsoredaffiliate role
    $info->{all_roles} =~ /sponsoredaffiliate/ and do {
      $hr_list = $entry->get_value('umichSponsorshipDetail', asref => 1);
      $hr_list and print OUTRPT "$patron_id: using umichsponsorshipdetail for faculty role\n";
    };
  };
  $hr_list or return 0;

  my @hr_filtered;
  my $hr_data;
  HR:foreach my $hr (@$hr_list) {
    $hr_data = parseField($hr);
    lc($hr_data->{jobCategory}) eq $info->{instRole} and push @hr_filtered, $hr_data;
    $info->{instRole} eq 'regularstaff' and  lc($hr_data->{jobCategory}) eq 'staff' and $hr_data->{regTemp} eq 'R' and push @hr_filtered, $hr_data;
    $info->{instRole} eq 'temporarystaff' and  lc($hr_data->{jobCategory}) eq 'staff' and $hr_data->{regTemp} eq 'T' and push @hr_filtered, $hr_data;
    $info->{instRole} eq 'retiree' and lc($hr_data->{jobCategory}) eq 'faculty' and push @hr_filtered, $hr_data;
    $info->{instRole} eq 'sponsoredaffiliate' and print OUTRPT "$patron_id: hr data from $attr\n" and push @hr_filtered, $hr_data;
  }
  scalar @hr_filtered or return 0;
  #scalar @hr_filtered > 1 and print OUTRPT "$patron_id: multiple hr_data segments ($attr); first used\n";
  scalar @hr_filtered > 1 and do {	# multiple segments selected--prioitize library department (code starts with "47")
    print OUTRPT "$patron_id: multiple hr_data segments ($attr); check for lib dept\n";
    foreach my $hr_data (@hr_filtered) {
      $hr_data->{deptId} =~ /^47/ and do {
        print OUTRPT "$patron_id: multiple hr_data segments ($attr); used segment with lib dept\n";
        return $hr_data;
      };
    }
  };
  scalar @hr_filtered > 1 and print OUTRPT "$patron_id: multiple hr_data segments ($attr); first used\n";
  return $hr_filtered[0];
}
  
sub processHRinfo {
  my $info = shift;
  my $entry = shift;
  
  my $attr = 'umichHR';
  $info->{instRole} eq 'sponsoredaffiliate' and $attr = 'umichSponsorshipDetail';
  my $hr_data = getHRdata($info, $entry, $attr) or return 0;
  
  foreach my $key ('jobCategory','deptId','deptDescription','jobcode','emplStatus','regTemp','umichSponsorStartDate','umichSponsorEndDate') {
    #$hr_data->{$key} and $info->{$key} = lc($hr_data->{$key});
    $hr_data->{$key} and $info->{$key} = $hr_data->{$key}; # lc might be necessary -- tlp (alma)
  }

  # add dept code to dept description
  $info->{deptId} and $info->{deptDescription} and do {
    $info->{deptDescription} .= join("", " (", $info->{deptId}, ")");
  };

  my $hr_campus;
  $hr_data->{campus} and do {
    $hr_campus = $campus_map{lc($hr_data->{campus})};
    $hr_campus ne $info->{campus} and do {
      print OUTRPT "$patron_id: campus set from hr_info for role $info->{instRole}: $hr_campus\n";
      $info->{campus} = $hr_campus;
    };
  };
  if ($info->{deptId}) {
    $info->{budget} = join("-", $info->{campus}, $info->{deptId});
  } else {
    $info->{budget} = $info->{campus};
  }

  ($info->{bstat}, $info->{btype}) = @{$role_to_bstat_btype{$info->{instRole}}};
  $info->{sponsorReason} eq 'Contractors' and do {
    $info->{btype} = 'CN';
    print OUTRPT "$patron_id: sponsoredaffiliate contractor, btype set to 'CN'\n"; 
  };
  $info->{jobcode} and do {
    $jobcode_to_btype{$info->{jobcode}} and do {
      $info->{btype} = $jobcode_to_btype{$info->{jobcode}};
      $info->{bstat} ne '01' and do {
        my $old_bstat = $info->{bstat}; 
        $info->{bstat} = '01';
        print OUTRPT join("\t", $patron_id, "bstat/btype set from jobcode", "$old_bstat set to  $info->{bstat}", $info->{btype}, $info->{jobcode}), "\n";
      };
    };
  };
  return 1;
}

sub processStudentInfo {
  my $info = shift;
  my $entry = shift;
  my $term_list = shift;	# hash ref, terms being loaded

  my $info_list = [];
  my $campus = $info->{campus};
  $info->{expire_date} = $expire_date_st;
  $info->{purge_date} = $purge_date_st;
  $campus eq 'UMAA' and do {
    my $selected_term = 0;
    my $all_terms = {};
    foreach my $ts ($entry->get_value('umichAATermStatus')) {
      my $ts_data = parseField($ts);
      $ts_data->{'regStatus'} =~ /(RGSD)/i 
        or $ts_data->{'acadCareer'} eq 'GRAC' 
        or next;
      my $termCode = substr($ts_data->{'termCode'}, 0, 3);
      $termCode < $term_map_min{$campus} and next;
      my $term = $term_map{$campus}{$termCode} or do {
        print  "$patron_id: can't map termcode $termCode\n";
        next;
      };
      $all_terms->{$term}++;
      $term_list->{$term} and $selected_term++;
    }
    $selected_term or do {
      my $all_terms_list = join(",", sort keys %$all_terms);
      print OUTRPT "$patron_id: no term selected ($all_terms_list)\n";
      $counters{"$info->{campus} student, no term selected"}++;
      return 0;
    };
        
    my $acad_prog_data;
    foreach my $ap ($entry->get_value('umichAAAcadProgram')) {
      $acad_prog_data = parseField($ap);
      last;
    }
    foreach my $key ('acadCareer','termCode','regStatus', 'acadProg','acadCareerDescr','acadProgDescr') {
      $acad_prog_data->{$key} and $info->{$key} = $acad_prog_data->{$key};
    }
    my $stat_type_key = substr($info->{'acadCareer'}, 0,1);
    $info->{'budget'} = join('-', $info->{campus}, substr($info->{'acadCareer'}, 0,1) . $info->{'acadProg'});
    $info->{'acadCareer'} eq 'GRAC' and $stat_type_key = $info->{'acadCareer'};
    $stat_type_key eq 'A' and $stat_type_key .= $info->{'acadProg'};
    defined $aa_pcode_prog_to_bstat_btype{$stat_type_key} or do {
      print OUTRPT join("\t", $info->{'uniqname'}, $info->{'acadCareer'}), ": invalid acadCareer\n";
      print OUTRPT join("\t", $info->{'acadCareer'},
        $info->{'acadCareerDescr'},
        $info->{'acadProg'},
        $info->{'acadProgDescr'},), "\n";
      return 0;
    };
    ($info->{'bstat'}, $info->{'btype'}) = @{$aa_pcode_prog_to_bstat_btype{$stat_type_key}};

    $info->{all_roles} =~ /temporarystaffaa/i and do {	# check for temp staff for library department
      $counters{"temp student employee"}++;
      STUDENT_HR:foreach my $hr ($entry->get_value("umichHR")) {
        my $hr_data = parseField($hr);
        $hr_data->{deptId} =~ /^47/ and do {
          $info->{deptId} = $hr_data->{deptId};
          $info->{budget} = join('-', $info->{campus}, $hr_data->{deptId});
          print OUTRPT "$patron_id: library student employee $info->{deptId}\n";
          $counters{"temp student employee (library)"}++;
          last STUDENT_HR;
        };
      }
    };
    return 1;
  };
  $info->{campus} =~ /^(UMDB|UMFL)$/ and do {
    termCheck($info, $entry, $term_list) or do {
      $counters{"$info->{campus} student, no term selected"}++;
      print OUTRPT "$patron_id: $info->{campus}, no term selected\n";
      return 0;
    };
    my $ts_attr = join('', 'umich', $info->{ldap_campus}, 'CurrentTermStatus');
    my $currentTermStatus = $entry->get_value($ts_attr) or do {
      print OUTRPT "$patron_id: no $ts_attr  for patron\n";
      return 0;
    };
    my $ts_data = parseField($currentTermStatus);
    foreach my $key ('academicPeriod','program','programDesc','classStanding','classStandingDesc') {
      $ts_data->{$key} and $info->{$key} = $ts_data->{$key};
    }
    if (defined $classStanding_to_bstat_btype{$info->{'classStanding'}}) {
      ($info->{'bstat'}, $info->{'btype'}) = @{$classStanding_to_bstat_btype{$info->{'classStanding'}}}; 
    } else {
      $info->{'bstat'} = '04';
      $info->{'btype'} = '  ';
      print OUTRPT join(", ", 
        $patron_id,
        "unknown classStanding code",
        $info->{'program'},
        $info->{'classStanding'},
        $info->{'classStandingDesc'},
      ), "\n";
      return 0;
    }
    $info->{budget} = $info->{campus};
    return 1;
  };
  print OUTRPT "$patron_id: unknown campus $info->{campus}\n";
  return 0;
}
 
sub termCheck {
  my $info = shift;
  my $entry = shift;
  my $term_list = shift;
  my $attr = join('', 'umich', $info->{ldap_campus}, 'TermStatus');
  my $terms = [];
  my $campus = $info->{campus};
  my $selected_term = 0;
  foreach my $ts ($entry->get_value($attr)) {
    my $ts_data = parseField($ts);
    $ts_data->{'registered'} eq 'Y' or next;
    my $academicPeriod = $ts_data->{'academicPeriod'};
    my $academicPeriodDesc = $ts_data->{'academicPeriodDesc'};
    $academicPeriod < $term_map_min{$campus} and next;
    my $term = $term_map{$campus}{$academicPeriod} or do {
      print OUTRPT "$patron_id: can't map academicPeriod $academicPeriod for campus $campus to term\n";
      next;
    };
    $term_list->{$term} and $selected_term++;
  }
  $selected_term or return 0;
#  print "$patron_id: ", join(", ", @$terms), "\n";
  return 1;
}

sub parseFieldList {
  # input: array of fields
  my $field_list = shift;
  
  my $parsed_field_list = [];
  foreach my $field ( @$field_list ) {
    my $data = parseField($field);
    push @$parsed_field_list, $data;
  }
  return $parsed_field_list;
}

sub parseField {
  # input: field
  # returns: hash of field: value
  my $field = shift;
  my $data = {};
  #foreach my $field_entry (split /:/, $field) {
  #foreach my $field_entry (split /}:{/, $field) {
  foreach my $field_entry (split /\}:\{/, $field) {
    $field_entry =~ tr/{}//d;
    my ($field_name, $field_data) = split(/=/, $field_entry);
    $data->{$field_name} = $field_data;
  }
  return $data;
}

sub LDAPerror {
  my ($from, $mesg) = @_;
  print OUTRPT "Return code: ", $mesg->code;
  print OUTRPT "\tMessage: ", $mesg->error_name;
  print OUTRPT " :",          $mesg->error_text;
  print OUTRPT "MessageID: ", $mesg->mesg_id;
  print OUTRPT "\tDN: ", $mesg->dn;
  print OUTRPT "\tMessage: ", $mesg->error;
  print OUTRPT "\n";
}

sub dump_entry {
  my $entry = shift;

  my $all_roles = $entry->get_value('umichInstRoles');
  
  print OUTRPT "DN: ", $entry->dn, "\n";
  #print "\n$info->{uniqname}:\t$all_roles\n";
  foreach my $attr ( sort $entry->attributes ) {
  #foreach my $attr ( sort @$attrs ) {
  #foreach my $attr ( 'umichHomePostalAddressData', 'umichPermanentPostalAddressData', 'umichPostalAddressData',) {
  #foreach my $attr ( 'umichHomePostalAddress', 'umichPermanentPostalAddress', 'umichPostalAddress',) {
     # skip binary we can't handle
     next if ( $attr =~ /;binary$/ );
     my $attr_value = $entry->get_value($attr);
     print OUTRPT "\t $attr: ", join(",", $attr_value) ,"\n";
     $attr_value or next;
  }
}

sub getDate {
  my $inputDate = shift;
  if (!defined($inputDate)) { $inputDate = time; }
  my ($ss,$mm,$hh,$day,$mon,$yr,$wday,$yday,$isdst) = localtime($inputDate);
  my $year = $yr + 1900;
  $mon++;
  #my $fmtdate = sprintf("%4.4d%2.2d%2.2d:%2.2d:%2.2d:%2.2d",$year,$mon,$day,$hh,$mm,$ss);
  my $fmtdate = sprintf("%4.4d%2.2d%2.2d:%2.2d:%2.2d:%2.2d",$year,$mon,$day,$hh,$mm,$ss);
  return $fmtdate;
}

sub get_name_parts {
  my $entry = shift;
  my $name_parts = {};

  my $first_name = $entry->get_value('givenName') or return 0;
  my $last_name = $entry->get_value('umichDisplaySN') or return 0;
  my $middle_name = $entry->get_value('umichDisplayMiddle');

  $name_parts->{first_name} = $first_name; 
  $name_parts->{last_name} = $last_name; 
  $middle_name and $name_parts->{middle_name} = $middle_name; 
  return $name_parts;
}

sub processName {
  # add first_name and last_name to info structure
  my $info = shift;
  my $entry = shift;
  my $name_parts = get_name_parts($entry);
  $name_parts and do {
    $info->{lastname} = $name_parts->{last_name}; 
    $info->{firstname} = $name_parts->{first_name}; 
    defined $name_parts->{middle_name} and $info->{middlename} = $name_parts->{middle_name}; 
    $counters{"Name from name parts"}++;
    return 1;
  };

  my $displayName = $entry->get_value('displayName') or do {
    print OUTRPT "$patron_id: no displayName in entry\n";
    dump_entry($entry);
    return 0;
  };
  $displayName =~ tr/ / /s;
  $info->{fullname} = $displayName;
  $name_parts = splitName($displayName);
  $name_parts and do {
    print OUTRPT "$patron_id: name from displayName ($displayName)\n";
    $info->{lastname} = $name_parts->{last_name}; 
    $info->{firstname} = $name_parts->{first_name}; 
    defined $name_parts->{middle_name} and $info->{middlename} = $name_parts->{middle_name}; 
    $counters{"Name from displayName"}++;
    return 1;
  };

  print OUTRPT "$patron_id: can't part name from entry\n";
  dump_entry($entry);
  return 0;
}

sub splitName {
  my $displayName = shift;
  my $name_parts = {};
  $displayName =~ /\s/ or do {
    print OUTRPT "$patron_id:  splitName: no whitespace in display name '$displayName'\n";
    $name_parts->{last_name} = $displayName;
    $name_parts->{first_name} = '(none)';
    return $name_parts;
  };
  my @name_words = split(/\s+/, $displayName);
  $name_parts->{last_name} = pop(@name_words);
  $name_parts->{first_name} = join(' ', @name_words);
  #my $fullname_lastfirst = join(', ', $lastname, $firstname);
  #print OUTRPT "$patron_id:  splitName: $displayName,  lastfirst $fullname_lastfirst\n";
  #return $fullname_lastfirst;
  return $name_parts;
}

