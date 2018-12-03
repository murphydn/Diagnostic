# this is an expansion of hpo_orpha.pl
# this is just a draft version of the diagnosis procedure

#!/usr/bin/perl
use strict;
use warnings;
use XML::Simple;
use Data::Dumper;
use List::MoreUtils 'uniq';

# create object
my $xml = new XML::Simple;

my $file = 'en_product4_HPO.xml';
# check file is present
if (-e $file) {
#  print "XML file is present.\n";
} else {
#  print "\nNo XML file present. Downloading Now.\n";
  system ('wget http://www.orphadata.org/data/xml/en_product4_HPO.xml');
}

#print "\nReading XML file.\n";

print "Below are listed the various HPO terms. Determine which symptoms the patient displays and enter the corresponding numbers separated by a space. When finished entering the information press Enter.\n\n";


# read XML file
my $data = $xml->XMLin($file);

#create orpha id hash
my %orpha_disease;
my %count;
my %hpo_terms;
my @all_hpo_terms;
my @all_hpo_freqs;
# 3 dimensional hash for the hpo frequencies
my %hpo_freqs;

my %disorders1 = %{ $data->{DisorderList}->{Disorder} };

for my $key (keys %disorders1) {
  $count{$key} = $disorders1{$key}->{HPODisorderAssociationList}->{count};
  my @hpos;
  my @hpo_freqs;
  # if the count is more than 1 create a hash 
  if ($count{$key} > 1) {
    my %hpo = %{ $disorders1{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation} };
    for my $hpo_key (keys %hpo) {
      push (@hpos, ($hpo{$hpo_key}->{HPO}->{HPOTerm}));
      push (@all_hpo_terms, ($hpo{$hpo_key}->{HPO}->{HPOTerm}));
      push (@all_hpo_freqs, ($hpo{$hpo_key}->{HPOFrequency}->{Name}->{content}));
      $hpo_freqs{$disorders1{$key}->{Name}->{content}}{$hpo{$hpo_key}->{HPO}->{HPOTerm}} = $hpo{$hpo_key}->{HPOFrequency}->{Name}->{content};
    }
    $hpo_terms{$disorders1{$key}->{Name}->{content}} = [@hpos];
  } else {
    $hpo_terms{$disorders1{$key}->{Name}->{content}} = $disorders1{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOTerm};
    $hpo_freqs{$disorders1{$key}->{Name}->{content}}{$disorders1{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOTerm}} = $disorders1{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPOFrequency}->{Name}->{content};
    push (@all_hpo_terms, ($disorders1{$key}->{HPODisorderAssociationList}->{HPODisorderAssociation}->{HPO}->{HPOTerm}));
  }
}

#print Dumper (%hpo_freqs);

# get the unique frequencies
#my @unique_freqs = uniq (@all_hpo_freqs);
#for my $element (sort @unique_freqs) {
#  print $element, "\n";
#}

# get the unique hpo terms and create a list
my %hpo_list;
my @unique_hpo = uniq (@all_hpo_terms);
my @sorted_hpo = sort @unique_hpo;
for (0..$#sorted_hpo) {
  my $pos = $_ + 1;
  $hpo_list{$pos} = $sorted_hpo[$_];
#  print "$pos $sorted_hpo[$_]\n";
}
#for my $element (sort @unique_hpo) {
#  print $element, "\n";
#}

# Take user input for the symptoms
#print "\n\nEnter numbers corresponding to visible symptoms/features, separated by spaces. Then press Enter.\n";

my $input = <STDIN>;
chomp $input;
my @symptoms = split (/\s+/, $input);

#print "\nYou have entered the following:\n";
foreach my $symptom (@symptoms) {
#  print $symptom, ": ", $hpo_list{$symptom}, "\n";
}
# print out the hpo terms for each disorder
#for my $disorder (keys %hpo_terms) {
#  if (ref($hpo_terms{$disorder}) eq "ARRAY") {
#    print $disorder, ": @{ $hpo_terms{$disorder} }\n";
#  } else {
#    print $disorder, ": ", $hpo_terms{$disorder};
#  }
#}

# below will only find the first symptom, next iteration will attempt to find all
my @returned_disorders = getdisorder(\%hpo_terms, $hpo_list{$symptoms[0]});

print "\nThese are the disorders with ", $hpo_list{$symptoms[0]}, " as a feature:\n\n";

foreach my $result (@returned_disorders) {
  print "  ", $result, "\n";
}

###############
# SUBROUTINES #
###############


sub getdisorder {
  my ($hash_input, $search_term) = @_;
  my @result;
  for my $key (keys %$hash_input) {
    if (ref $hash_input->{$key} eq 'ARRAY') {
      for (@{$hash_input->{$key}}) {
        push @result, $key if /^$search_term$/i;
      }
    } else {
      push @result, $key if $hash_input->{$key} =~ /^$search_term$/i;
    }
  }
  return @result;
}


sub remove_duplicates {
  my $ar = shift;
  my %seen;
  for ( my $i = 0; $i <= $#{$ar} ; ) {
    splice @$ar, --$i, 1
      if $seen{$ar->[$i++]}++;
  }
}

exit;



