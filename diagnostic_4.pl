# this is just a draft version of the diagnosis procedure
# where diagnostic_2 left of 
# if the list of diseases is this will resturn a set of symptoms that should help distinguish between them

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
unless (-e $file) {
  print "\nNo XML file present. Downloading Now.\n";
  system ('wget http://www.orphadata.org/data/xml/en_product4_HPO.xml');
}

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
  print "$pos\t$sorted_hpo[$_]\n";
}

# Take user input for the symptoms
print "\n\nEnter numbers corresponding to visible symptoms/features, separated by spaces. Then press Enter.\n";

my $input = <STDIN>;
chomp $input;

my @symptom_refs = split (/\s+/, $input);
my @symptoms;

if ($input) {
  print "\nYou have entered the following:\n";
  foreach my $symptom_ref (@symptom_refs) {
    print $symptom_ref, ": ", $hpo_list{$symptom_ref}, "\n";
    push (@symptoms, $hpo_list{$symptom_ref});
  }
} else {
  print "No symptoms entered!!\n";
  exit;
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
#  print "@symptoms\n";
#  print Dumper (%hpo_terms);
my @returned_disorders = getdisorder(\%hpo_terms, @symptoms);

if (scalar @returned_disorders == 0) {
  print "\nThere are no disorders corresponding to the symptoms that you selected.\n\n";
} elsif (scalar @symptoms == 1) {
  print "\nThese are the disorders with ", @symptoms, " as a feature:\n\n";
} elsif (scalar @symptoms > 1) {
  my $string = join (', ', @symptoms);
  print "\nThese are the disorders with ", $string, " as features:\n\n";
}

foreach my $result (@returned_disorders) {
  print "  ", $result, "\n";
}

# Differential diagnosis
# take the remaining symptoms that weren't filled in for the selection of diseases and list them
if (scalar @returned_disorders > 1) {
  my @hpo_list2;
  my %lookup1 = ();
  # create a new hash that has each of the disorders and all their remaining symptoms as key and value
  my %differential;
  foreach my $potential (@returned_disorders) {
    my @all_symptoms = @{$hpo_terms{$potential}};
    #print "@all_symptoms\n";
    # remove the already stated symptoms from each value
    my %lookup2 = ();
    my @remaining_symptoms;
    @lookup2{@symptoms} = ();
    foreach my $element (@all_symptoms) {
      push (@remaining_symptoms, $element) unless exists $lookup2{$element};
      unless (exists $lookup1{$element}) {
        push (@hpo_list2, $element);
        $lookup1{$element} = 1;
      }
    }
    $differential{$potential} = [@remaining_symptoms];
  }
  print "\n\nEnter numbers corresponding to any remaining visible symptoms/features, separated by spaces. Then press Enter.\n";
  my %new_symptom_list;
  my @sorted_hpo_list2 = sort @hpo_list2;
  for (0..$#sorted_hpo_list2) {
    my $pos = $_ + 1;
    $new_symptom_list{$pos} = $sorted_hpo_list2[$_];
    print $pos, "\t", $new_symptom_list{$pos}, "\n";
  }
  print "\n";

  my $new_input = <STDIN>;
  chomp $new_input;

  my @new_symptom_refs = split (/\s+/, $new_input);
  my @new_symptoms;

  if ($new_input) {
    print "\nYou have entered the following:\n";
    foreach my $symptom_ref (@new_symptom_refs) {
      print $symptom_ref, ": ", $new_symptom_list{$symptom_ref}, "\n";
      push (@new_symptoms, $new_symptom_list{$symptom_ref});
    }
  } else {
    print "No symptoms entered!!\n";
    exit;
  }
  #print "@new_symptoms\n";
  #print Dumper (%hpo_term);
  my @new_disorders = getdisorder(\%differential, @new_symptoms);
  #print "@new_disorders\n";
  if (scalar @new_disorders == 0) {
    print "\nThere are no disorders corresponding to the symptoms that you selected.\n\n";
  } elsif (scalar @new_symptoms == 1) {
    print "\nThese are the disorders with ", @new_symptoms, " as an additional feature:\n\n";
  } elsif (scalar @new_symptoms > 1) {
    my $string = join (', ', @new_symptoms);
    print "\nThese are the disorders with ", $string, " as additional features:\n\n";
  }
  foreach my $result (@new_disorders) {
    print "  ", $result, "\n";
  }
  print "\n";
  #print Dumper (%differential);
}



###############
# SUBROUTINES #
###############

sub getdisorder {
  my ($hash_input, @search_terms) = @_;
  my $no_terms = scalar @search_terms;
  my @result;
  my @del_list;
  for my $key (keys %$hash_input) {
    # start by adding all disorders that have the first feature
    if (ref $hash_input->{$key} eq 'ARRAY') {
      for (@{$hash_input->{$key}}) {
        push @result, $key if /^$search_terms[0]$/i;
      }
    } elsif ($no_terms == 1) {
      # if just one symtom add the disorders to the list
      push @result, $key if $hash_input->{$key} =~ /^$search_terms[0]$/i;
    }
  }
  # next remove the disorders from the list if they don't contain the remaining features
  # go through the result array one by one and remove the element if its array doesn't contain the symptoms
  # only do this next part if there was more than 1 symptom
  if ($no_terms > 1) {
    for (my $n = 0; $n < scalar @result; $n++) {
      for (my $i = 1; $i < $no_terms; $i++) {
        unless (grep ( /^$search_terms[$i]$/i, @{$hash_input->{$result[$n]}})) {
          push @del_list, $result[$n];
        }
      }
    }
  }
  # now get the array elements in result but not the delete list
  my %seen; # lookup table
  my @aonly;# answer

  # build lookup table
  @seen{@del_list} = ();
  foreach my $item (@result) {
    push(@aonly, $item) unless exists $seen{$item};
  }
  return @aonly;
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



