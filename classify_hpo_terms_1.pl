# this script will split up the hpo file into the inidvidual terms and create appropriate hashes for each term

use strict;
use warnings;
use Data::Dumper;
use XML::Simple;
use List::MoreUtils 'uniq';

my $hpo_url = 'https://raw.githubusercontent.com/obophenotype/human-phenotype-ontology/master/hp.obo';

my $hpo_file = 'hp.obo';

# check file is present
unless (-e $hpo_file) {
  print "\nNo HPO file present. Downloading Now.\n";
  system ('wget ' . $hpo_url);
}

open (HPOFILE, $hpo_file);

#while (my $line = <FILE>) {
local $/;
# split the file into array of terms
my @hpo_terms  = split("\\[Term\\]", <HPOFILE>);

my %id_hash;
my %name_hash;
my %def;
# for each element of the array add parts to hashes
foreach my $element (@hpo_terms) {
  my @entire = split (/\n/, $element);
  my @names = grep /name: /, @entire;
  my $name;
  my @ids = grep /^id: /, @entire;
  my $id;
  my @isa = grep /is_a: /, @entire;
  if (scalar @names > 1) {
    print "Too many names\n";
    exit;
  } else {
    $name = "@names";
    $name =~ s/name: //;
  } 
  if (scalar @ids > 1) {
    print "Too many ids\n";
    exit;
  } else {
    $id = "@ids";
    $id =~ s/id: //;
    $id_hash {$name} = $id;
    $name_hash {$id} = $name;
  }
}

#print Dumper (%def);

# create object
my $xml = new XML::Simple;

my $xml_file = 'en_product4_HPO.xml';

# check file is present
unless (-e $xml_file) {
  print "\nNo XML file present. Downloading Now.\n";
  system ('wget http://www.orphadata.org/data/xml/en_product4_HPO.xml');
}

# read XML file
#print "Reading XML file\n\n";
my $data = $xml->XMLin($xml_file);

#create hpo id hash
my %hpo_ids;
my %count;

my %disorders = %{ $data->{DisorderList}->{Disorder} };

for my $key (keys %disorders) {
  $count{$key} = $disorders{$key}->{HPODisorderAssociationList}->{count};
  # if the count is more than 1 create a hash
  if ($count{$key} > 1) {
    my %hpo = %{ $disorders{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation} };
    for my $hpo_key (keys %hpo) {
      unless ($hpo_ids{$hpo{$hpo_key}->{HPO}->{HPOId}}) {
        if ($name_hash{$hpo{$hpo_key}->{HPO}->{HPOId}}) {
          #print $hpo{$hpo_key}->{HPO}->{HPOId}, "\t", $hpo{$hpo_key}->{HPO}->{HPOTerm}, "\n";
          $hpo_ids{$hpo{$hpo_key}->{HPO}->{HPOId}} = $hpo{$hpo_key}->{HPO}->{HPOTerm};
 #       } else {
 #         print $hpo{$hpo_key}->{HPO}->{HPOId}, "\t", $hpo{$hpo_key}->{HPO}->{HPOTerm}, " not found.\n";
        }
      }
    }
  } else {
    unless ($hpo_ids{$disorders{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOId}}) {
      if ($name_hash{$disorders{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOId}}) {
        #print $disorders{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOId}, "\t", $disorders{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOTerm}, "\n";
        $hpo_ids{$disorders{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOId}} = $disorders{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOTerm};
#      } else {
#        print $disorders{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOId}, "\t", $disorders{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOTerm}, " not found.\n";
      }
    }
  }
}

#print Dumper (%hpo_ids);
#my %hpo_list;
#my @unique_hpo = uniq (@all_hpo_terms);
#my @sorted_hpo = sort @unique_hpo;

#foreach my $term (@sorted_hpo) {
#  print $id {$term}, "\t", $term, "\n";
#}
#for (0..$#sorted_hpo) {
#  my $pos = $_ + 1;
#  $hpo_list{$pos} = $sorted_hpo[$_];
#}
