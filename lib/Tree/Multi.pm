#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I.
#-------------------------------------------------------------------------------
# Multi-way tree in Pure Perl.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Tree::Multi;
our $VERSION = "20210528";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use feature qw(say current_sub);

our $debug = 0;                                                                 # Debugging if true
our $keysPerNode = 3;                                                           # Keys per node

#D1 Multi-way Tree                                                              # Create and use a multi-way tree.

my $nodes = 0;

sub new()                                                                       #P Create a new multi-way tree node
 {my () = @_;                                                                   # Key, $data, parent node, index of link from parent node
  genHash(__PACKAGE__,                                                          # Multi tree node
    number=> ++$nodes,                                                          # Number of the node for debugging purposes
    up    => undef,                                                             # Parent node
    keys  => [],                                                                # Array of key items for this node
    data  => [],                                                                # Data corresponding to each key
    node  => [],                                                                # Child nodes
   );
 }

sub check($)                                                                    # Check the integrity of a node
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  confess unless $tree->keys->@* == $tree->data->@*;
  confess if $tree->up and !$tree->up->node and !$tree->up->node->@*;
  __SUB__->($tree->up) if $tree->up;
  return unless my @n = $tree->node->@*;
  confess unless $tree->keys->@*+1 == @n;
 }

sub minimumNumberOfKeys  {int $keysPerNode / 2}                                 #P Minimum number of keys per node
sub maximumNumberOfKeys  {    $keysPerNode}                                     #P Maximum number of keys per node
sub maximumNumberOfNodes {    $keysPerNode + 1}                                 #P Maximum number of children per parent

sub fullNode($)                                                                 #P Confirm that a node is full
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  $tree->keys->@* == maximumNumberOfKeys
 }

sub halfNode($)                                                                 #P Confirm that a node is half full
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  $tree->keys->@* == minimumNumberOfKeys
 }

sub root($)                                                                     # Return the root node of a tree
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  for(; $tree->up; $tree = $tree->up) {}
  $tree
 }

sub leaf($)                                                                     # Confirm that the tree is a leaf
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  ! scalar $tree->node->@*                                                      # No children so it must be a leaf
 }

sub separateKeys($)                                                             #P Return ([lower], center, [upper]) keys
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  my @k = $node->keys->@*;
  my @l; my @r;
  while(@k > 1)
   {push    @l, shift @k;
    unshift @r, pop   @k if @k > 1;
   }
  @l > 0  or confess;
  @r > 0  or confess;
  @k == 1 or confess;
  (\@l, $k[0], \@r);
 }

sub separateData($)                                                             #P Return ([lower], center, [upper]) data
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  my @d = $node->data->@*;
  my @l; my @r;
  while(@d > 1)
   {push    @l, shift @d;
    unshift @r, pop   @d if @d > 1;
   }
  @l > 0 or confess;
  @r > 0 or confess;
  @d == 1 or confess;
  (\@l, $d[0], \@r);
 }

sub separateNode($)                                                             #P Return ([lower], [upper]) children
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  my @n = $node->node->@*;
  @n == maximumNumberOfNodes or confess;

  my @l; my @r;
  while(@n > 1)
   {push    @l, shift @n;
    unshift @r, pop   @n;
   }
  @l > 0 && @r > 0 && @n == 0 or confess;
  (\@l, \@r);
 }

sub reUp($@)                                                                    #P Reconnect the children to their new parent
 {my ($node, @children) = @_;                                                   # Node, children
  @_ > 1 or confess;

  for my $c(@children)                                                          # Add new child to parent known to be not full
   {$c->up = $node;
   }
 }

sub splitNode($)                                                                #P Split a full node in half assuming it has a non full parent
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess unless my $p = $node->up;                                             # Check parent
  confess unless $node->node->@* == maximumNumberOfNodes;                           # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;
  my ($cl, $cr)     = separateNode $node;

  my ($nl, $nr)     = (new, new);
  $nl->up = $nr->up = $p;
  $nl->keys = $kl; $nl->data = $dl; $nl->node = $cl; reUp($nl, @$cl);
  $nr->keys = $kr; $nr->data = $dr; $nr->node = $cr; reUp($nr, @$cr);

  my @n = $p->node->@*;
  for my $i(keys @n)                                                            # Add new child to parent known to be not full
   {if ($n[$i] == $node)
     {splice $p->keys->@*, $i, 0, $k;
      splice $p->data->@*, $i, 0, $d;
      splice $p->node->@*, $i, 1, $nl, $nr;
      return $p;                                                                # Return parent as we have delete the original node
     }
   }
  confess;
 }

sub splitRootNode($)                                                            #P Split a full root
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess if $node->up;                                                         # Check parent
  confess unless $node->node->@* == maximumNumberOfNodes;                           # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;
  my ($cl, $cr)     = separateNode $node;

  my $p = new;
  my ($nl, $nr)     = (new, new);
  $nl->up = $nr->up = $p;
  $nl->keys = $kl; $nl->data = $dl; $nl->node = $cl; reUp($nl, @$cl);
  $nr->keys = $kr; $nr->data = $dr; $nr->node = $cr; reUp($nr, @$cr);

  $p->keys = [$k];
  $p->data = [$d];
  $p->node = [$nl, $nr];
  $p                                                                            # Return new root
 }

sub splitFullNode($)                                                            #P Split a full node and return the new parent or return the existing node if it does not need to be split
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;
  return $node unless $node->node->@* == maximumNumberOfNodes;                      # Check size
  return splitNode     $node if $node->up;                                      # Node has a parent
  return splitRootNode $node                                                    # Root node
 }

sub splitLeafNode($)                                                            #P Split a full leaf node in assuming it has a non full parent
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess unless my $p = $node->up;                                             # Check parent
  confess unless $node->keys->@* == maximumNumberOfNodes;                           # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;

  my ($nl, $nr)     = (new, new);
  $nl->up = $nr->up = $p;
  $nl->keys = $kl; $nl->data = $dl;
  $nr->keys = $kr; $nr->data = $dr;

  my @n = $p->node->@*;
  for my $i(keys @n)                                                            # Add new child to parent known to be not full
   {if ($n[$i] == $node)
     {splice $p->keys->@*, $i, 0, $k;
      splice $p->data->@*, $i, 0, $d;
      splice $p->node->@*, $i, 1, $nl, $nr;
      return $p;                                                                # Return parent as we have delete the original node
     }
   }
  confess;
 }

sub splitRootLeafNode($)                                                        #P Split a full root that is also a leaf
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  confess if $node->up;                                                         # Check parent
  confess unless $node->keys->@* == maximumNumberOfNodes;                           # Check size

  my ($kl, $k, $kr) = separateKeys $node;
  my ($dl, $d, $dr) = separateData $node;

  my $p = new;
  my ($nl, $nr)     = (new, new);
  $nl->up = $nr->up = $p;
  $nl->keys = $kl; $nl->data = $dl;
  $nr->keys = $kr; $nr->data = $dr;

  $p->keys = [$k];
  $p->data = [$d];
  $p->node = [$nl, $nr];
  $p                                                                            # Return new root
 }

sub splitFullLeafNode($)                                                        #P Split a full leaf and return the new parent or return the existing node if it does not need to be split
 {my ($node) = @_;                                                              # Node to split
  @_ == 1 or confess;

  return $node if $node->keys->@* <= maximumNumberOfKeys;                       # Check size
  return splitLeafNode     $node if $node->up;                                  # Node has a parent
  return splitRootLeafNode $node                                                # Root node
 }

sub findAndSplit($$)                                                            # Find a key in a tree splitting full nodes along the path to the key
 {my ($tree, $key) = @_;                                                        # Tree, key
  @_ == 2 or confess;

  $tree = splitFullNode $tree;
  confess unless my @k = $tree->keys->@*;                                       # We should have at least one key in the tree

  if ($key < $k[0])                                                             # Less than smallest key in node
   {if (my $node = $tree->node->[0])
     {return __SUB__->($node, $key);
     }
    return (-1, $tree, 0);
   }

  if ($key > $k[-1])                                                            # Greater than largest key in node
   {if (my $node = $tree->node->[-1])                                           # Step through
     {return __SUB__->($node, $key);
     }
    return (+1, $tree, $#k);                                                    # Leaf
   }

  for my $i(keys @k)                                                            # Search the keys in this node
   {my $s = $key <=> $k[$i];                                                    # Compare key
    return (0, $tree, $i) if $s == 0;                                           # Found key
    if ($s < 0)                                                                 # Less than current key
     {if (my $node = $tree->node->[$i])                                         # Step through
       {return __SUB__->($node, $key);
       }
      return (-1, $tree, $i);                                                   # Leaf
     }
   }
  confess 'Not possible';
 } # findAndSplit

sub find($$)                                                                    # Find a key in a tree returning its associated data or undef if the key does not exist
 {my ($tree, $key) = @_;                                                        # Tree, key
  @_ == 2 or confess;
  my @k = $tree->keys->@*;

  if ($key < $k[0])                                                             # Less than smallest key in node
   {if (my $node = $tree->node->[0])
     {return __SUB__->($node, $key);
     }
    return undef;
   }

  if ($key > $k[-1])                                                           # Greater than largest key in node
   {if (my $node = $tree->node->[-1])
     {return __SUB__->($node, $key);
     }
    return undef;
   }

  for my $i(keys @k)                                                            # Search the keys in this node
   {my $s = $key <=> $k[$i];                                                    # Compare key
    return $tree->data->[$i] if $s == 0;                                        # Found key
    if ($s < 0)                                                                 # Less than current key
     {if (my $node = $tree->node->[$i])
       {return __SUB__->($node, $key);
       }
      return undef;
     }
   }
  confess 'Not possible';
 } # find

sub findNode($$)                                                                # Find the node containing a key.
 {my ($tree, $key) = @_;                                                        # Tree, key
  @_ == 2 or confess;
  my @k = $tree->keys->@*;

  if ($key < $k[0])                                                             # Less than smallest key in node
   {if (my $node = $tree->node->[0])
     {return __SUB__->($node, $key);
     }
    return undef;
   }

  if ($key > $k[-1])                                                           # Greater than largest key in node
   {if (my $node = $tree->node->[-1])
     {return __SUB__->($node, $key);
     }
    return undef;
   }

  for my $i(keys @k)                                                            # Search the keys in this node
   {my $s = $key <=> $k[$i];                                                    # Compare key
    return $tree if $s == 0;                                                    # Found key so return node
    if ($s < 0)                                                                 # Less than current key
     {if (my $node = $tree->node->[$i])
       {return __SUB__->($node, $key);
       }
      return undef;
     }
   }
  confess 'Not possible';
 } # find

sub indexInParent($)                                                            #P Get the index of a node in its parent
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  my $p = $tree->up;
  confess unless defined $p;
  my @n = $p->node->@*;
  for my $i(keys @n)
   {return $i if $n[$i] == $tree;
   }
  confess
 }

sub mergeableWithPrevOrNextOnDelete($)                                          #P Check whether a node can be merged with its previous or next element returning a pair of indices defining the mergable elements as seen by the parent or an empty pair if no elements are mergeable.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  my $N = $tree->keys->@*;
  return 0 if $N == $keysPerNode;                                               # Node is full so it cannot be merged
  my $p = $tree->up;
  my $n = $p->nodes->@* - 1;
  my $K = maximumNumberOfKeys;
  if (my $i = $tree->indexInParent)
   {return ($i-1, $i) if $i >  0 and $p->node->[$i-1]->keys->@* + $N < $K;      # Less than because we are going to include the parent key
    return ($i, $i+1) if $i < $n and $p->node->[$i+1]->keys->@* + $N < $K;
    return ()
   }
  confess
 }

sub mergeablePairOfChildrenOnDelete($$)                                         #P Check whether the children on either side of a key can be merged before deleting the indexed key
 {my ($tree, $index) = @_;                                                      # Tree, index of key
  @_ == 2 or confess;
  $tree->node->[$index]->keys->@* + $tree->node->[$index+1]->keys->@* <=        # Less than or equal because we will be deleting the parent key
    maximumNumberOfKeys;
 }

sub fillFromLeftOrRight($$)                                                     #P Fill a  node from the specified sibling
 {my ($n, $dir) = @_;                                                           # Node to fill, node to fill from 0 for left or 1 for right
  @_ == 2 or confess;

  confess unless    $n->halfNode;                                               # Confirm leaf is half full
  confess unless my $p = $n->up;                                                # Parent of leaf
  my $i = $n->indexInParent;                                                    # Index of leaf in parent

  if ($dir)                                                                     # Fill from right
   {$i < $p->node->@* - 1 or confess;                                           # Cannot fill from right
    my $r = $p->node->[$i+1];                                                   # Leaf on right
    push $n->keys->@*, $p->keys->[$i]; $p->keys->[$i] = shift $r->keys->@*;     # Transfer key
    push $n->data->@*, $p->data->[$i]; $p->data->[$i] = shift $r->data->@*;     # Transfer data
    if (!$n->leaf)                                                              # Transfer node if not a leaf
     {push $n->node->@*, shift $r->node->@*;
      $n->node->[-1]->up = $n;
     }
   }
  else                                                                          # Fill from left
   {$i > 0 or confess;                                                          # Cannot fill from left
    my $l = $p->node->[$i-1];                                                   # Leaf on leaf
    unshift $n->keys->@*, $p->keys->[$i-1];$p->keys->[$i-1] = pop $l->keys->@*; # Transfer key
    unshift $n->data->@*, $p->data->[$i-1];$p->data->[$i-1] = pop $l->data->@*; # Transfer data
    if (!$n->leaf)                                                              # Transfer node if not a leaf
     {unshift $n->node->@*, pop $l->node->@*;
      $n->node->[0]->up = $n;
     }
   }
 }

sub fillFromLeft($)                                                             #P Fill a node from the left
 {my ($n) = @_;                                                                 # Node to fill
  fillFromLeftOrRight($n, 0)
 }

sub fillFromRight($)                                                            #P Fill a node from the right
 {my ($n) = @_;                                                                 # Leaf to fill
  fillFromLeftOrRight($n, 1)
 }

sub mergeWithLeftOrRight($$)                                                    #P Merge two adjacent nodes
 {my ($n, $dir) = @_;                                                           # Node to merge into, node to merge is on right if 1 else left
  @_ == 2 or confess;

  confess unless    $n->halfNode;                                               # Confirm leaf is half full
  confess unless my $p = $n->up;                                                # Parent of leaf
  confess if        $p->halfNode and $p->up;                                    # Parent must have more than the minimum number of keys because we need to remove one unless it is the root of the tree

  my $i = $n->indexInParent;                                                    # Index of leaf in parent

  if ($dir)                                                                     # Merge with right hand sibling
   {$i < $p->node->@* - 1 or confess;                                           # Cannot fill from right
    my $r = $p->node->[$i+1];                                                   # Leaf on right
    confess unless $r->halfNode;                                                # Confirm right leaf is half full
    push $n->keys->@*, splice($p->keys->@*, $i, 1), $r->keys->@*;               # Transfer keys
    push $n->data->@*, splice($p->data->@*, $i, 1), $r->data->@*;               # Transfer data
    if (!$n->leaf)                                                              # Children of merged node
     {push $n->node->@*, $r->node->@*;                                          # Children of merged node
      $_->up  = $n for $r->node->@*;                                            # Update parent of children of right node
     }
    splice $p->node->@*, $i+1, 1;                                               # Remove link from parent to right child
   }
  else                                                                          # Merge with left hand sibling
   {$i > 0 or confess;                                                          # Cannot fill from left
    my $l = $p->node->[$i-1];                                                   # Node on left
    confess unless $l->halfNode;                                                # Confirm right leaf is half full
    unshift $n->keys->@*, $l->keys->@*, splice $p->keys->@*, $i-1, 1;           # Transfer keys
    unshift $n->data->@*, $l->data->@*, splice $p->data->@*, $i-1, 1;           # Transfer data
    if (!$n->leaf)                                                              # Children of merged node
     {unshift $n->node->@*, $l->node->@*;                                       # Children of merged node
      $_->up  = $n for $l->node->@*;                                            # Update parent of children of left node
     }
    splice $p->node->@*, $i-1, 1;                                               # Remove link from parent to left child
   }
 }

sub mergeWithLeft($)                                                            #P Merge a node from the left
 {my ($n) = @_;                                                                 # Node to merge into
  mergeWithLeftOrRight($n, 0)
 }

sub mergeWithRight($)                                                           #P Merge a node from the right
 {my ($n) = @_;                                                                 # Node to merge into
  mergeWithLeftOrRight($n, 1)
 }

sub mergeRoot($$)                                                               #P Merge the root node
 {my ($tree, $child) = @_;                                                      # Tree
  @_ == 2 or confess;
  confess if $tree->up;                                                         # Must be at the root

  if ($tree->keys->@* == 1)
   {if (!$tree->leaf)
     {if ((my $l = $tree->node->[0])->halfNode)
       {if ((my $r = $tree->node->[1])->halfNode)
         {if ($l == $child)
           {push $l->keys->@*, $tree->keys->@*,  $r->keys->@*;
            push $l->data->@*, $tree->data->@*,  $r->data->@*;
            push $l->node->@*, $r->node->@*;
            $_->up = $l for $r->node->@*;
            $l->up = undef;
            return $l;
           }
          else
           {unshift $r->keys->@*, $l->keys->@*, $tree->keys->@*;
            unshift $r->data->@*, $l->data->@*, $tree->data->@*;
            unshift $r->node->@*, $l->node->@*;
            $_->up = $r for $l->node->@*;
            $r->up = undef;
            return $r;
           }
         }
       }
     }
   }
  return undef;
 }

sub mergeOrFill($)                                                              #P make a node larger than a half node
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;

  return 0 unless $tree->halfNode;                                              # No need if not a half node

  my $p = $tree->up;                                                            # Parent
  if ($p and $p->up)
   {if ($p->halfNode)
     {$p->mergeOrFill;                                                          # Ensure parent is not a half node
     }
   }
  elsif ($p and $p->keys->@* == 1)
   {my $i = $tree->indexInParent;
     my $q = $p->mergeRoot($tree);
     if ($q) {$p = $q; return $i ? 2 : 0}
   }
  elsif (!$p) {return 0;}

  my $i = $tree->indexInParent;
  if ($i > 0)                                                                   # Merge with left node
   {my $l = $p->node->[$i-1];                                                   # Left node
    my $r = $tree;                                                              # Right node
    if ($r->halfNode)
     {if ($l->halfNode)                                                         # Left and right must be half nodes, the parent yields  a key so it must be more than half full
       {$r->mergeWithLeft;
        return 1 + minimumNumberOfKeys;                                         # The extent to which we have been shifted over
       }
      else                                                                      # Left and right must be half nodes, the parent yields  a key so it must be more than half full
       {$r->fillFromLeft;
        return 1;
       }
     }
    confess;                                                                    # No action required as the node is more than half full
   }
  else                                                                          # Merge with right node
   {my $r = $p->node->[$i+1];                                                   # Left node
    my $l = $tree;                                                              # Right node
    if ($l->halfNode)
     {if ($r->halfNode)                                                         # Left and right must be half nodes, the parent yields  a key so it must be more than half full
       {$l->mergeWithRight;
        return 0;
       }
      else                                                                      # Left and right must be half nodes, the parent yields  a key so it must be more than half full
       {$l->fillFromRight;
        return 0;
       }
     }
    confess;                                                                    # No action required as the node is more than half full
   }
  confess;
 }

sub leftMostNode($)                                                             # Return the left most node below the specified one
 {my ($tree) = @_;                                                              # Tree
  return $tree if $tree->leaf;                                                  # We are on a leaf so we have arrived at the left most node
  $tree->node->[0]->leftMostNode;                                               # Go left
 }

sub rightMostNode($)                                                            # Return the right most node below the specified one
 {my ($tree) = @_;                                                              # Tree
  return $tree if $tree->leaf;                                                  # We are on a leaf so we have arrived at the left most node
  $tree->node->[-1]->rightMostNode;                                             # Go right
 }

sub deleteElement($$)                                                           #P Delete an element in a node
 {my ($tree, $i) = @_;                                                          # Tree, index to delete at
  @_ == 2 or confess;
  $i += $tree->mergeOrFill;                                                     # Increase by one if from left
  if ($tree->leaf)                                                              # Delete from a leaf
   {       splice $tree->keys->@*, $i, 1;                                       # Remove keys
    return splice $tree->data->@*, $i, 1;                                       # Remove data and return it
   }
  elsif ($i > 0)                                                                # Delete from a node
   {my $r = $tree->node->[$i-1]->leftMostNode;                                  # Find previous node
    $r->deleteElement(scalar $r->keys->@*);                                     # Remove leaf
           splice $tree->keys->@*, $i, 1, $r->keys->[-1];                       # Transfer key
    return splice $tree->data->@*, $i, 1, $r->data->[-1];                       # Transfer data
   }
  else                                                                          # Delete from a node
   {my $r = $tree->node->[$i+1]->rightMostNode;                                 # Find previous node
    $r->deleteElement(0);                                                       # Remove leaf
           splice $tree->keys->@*, $i, 1, $r->keys->[0];                        # Transfer key
    return splice $tree->data->@*, $i, 1, $r->data->[0];                        # Transfer data
   }
 }

sub delete($$)                                                                  # Find a key in a tree, delete it, return the new tree
 {my ($tree, $key) = @_;                                                        # Tree, key
  @_ == 2 or confess;
  my @k = $tree->keys->@*;

  if (@k == 1 and !$k[0] == $key and $tree->up and $tree->node->@* == 0)        # Delete the root node
   {return new;
   }

  if ($key < $k[0])                                                             # Less than smallest key in node
   {if (my $node = $tree->node->[0])
     {return __SUB__->($node, $key);
     }
    return $tree->root;
   }

  if ($key > $k[-1])                                                            # Greater than largest key in node
   {if (my $node = $tree->node->[-1])
     {return __SUB__->($node, $key);
     }
    return $tree->root;
   }

  for my $i(keys @k)                                                            # Search the keys in this node
   {my $s = $key <=> $k[$i];                                                    # Compare key
    if ($s == 0)                                                                # Delete found key
     {deleteElement($tree, $i);                                                 # Delete
      return $tree->root;                                                       # New tree
     }
    if ($s < 0)                                                                 # Less than current key
     {if (my $node = $tree->node->[$i])
       {return __SUB__->($node, $key);
       }
      return $tree->root;
     }
   }
  confess 'Not possible';
 } # delete

sub insert($$$)                                                                 # Insert a key and data into a tree
 {my ($tree, $key, $data) = @_;                                                 # Tree, key, data
  @_ == 3 or confess;

  if (!$tree->keys->@*)                                                         # Empty tree
   {push $tree->keys->@*, $key;
    push $tree->data->@*, $data;
    return $tree;
   }

  my ($compare, $node, $index) = findAndSplit($tree, $key);                     # Check for existing key

  if ($compare == 0)                                                            # Found an equal key whose data we can update
   {$node->data->[$index] = $data;
    return root $node;
   }

  if ($compare < 0)                                                             # Insert into a leaf node below the index
   {my @k = $node->keys->@*; my @d = $node->data->@*;
    $node->keys = [@k[0..$index-1], $key,  @k[$index..$#k]];
    $node->data = [@d[0..$index-1], $data, @d[$index..$#d]];
   }
  else                                                                          # Insert into a leaf node node above the index
   {my @k = $node->keys->@*; my @d = $node->data->@*;
    $node->keys = [@k[0..$index], $key,  @k[$index+1..$#k]];
    $node->data = [@d[0..$index], $data, @d[$index+1..$#d]];
   }
  root splitFullLeafNode $node
 }

sub printKeysAndData($)                                                         # Print the mapping from keys to data in a tree
 {my ($t) = @_;                                                                 # Tree
  confess unless $t;
  my @s;
  my $print = sub
   {my ($t, $in) = @_;
    return unless $t and $t->keys;
    push @s, join ' ', ('  'x$in), $t->keys->@*, ' ', $t->data->@*;             # Print keys

    if (my $nodes = $t->node)                                                   # Each key
     {for my $n($nodes->@*)                                                     # Each key
       {__SUB__->($n, $in+1);                                                   # Sub tree
       }
     }
   };

  $print->($t->root, 0);

  join "\n", @s;
 }

sub printKeys($)                                                                # Print the keys in a tree
 {my ($t) = @_;                                                                 # Tree
  confess unless $t;
  my @s;
  my $print = sub
   {my ($t, $in) = @_;
    return unless $t and $t->keys and $t->keys->@*;
    push @s, join ' ', ('  'x$in), $t->keys->@*;                                # Print keys

    if (my $nodes = $t->node)                                                   # Each key
     {for my $n($nodes->@*)                                                     # Each key
       {__SUB__->($n, $in+1);                                                   # Sub tree
       }
     }
   };
  $print->($t->root, 0);

  join "\n", @s, '';
 }

#d
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(
 );
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Tree::Multi - Multi-way tree in Pure Perl

=head1 Synopsis


=head1 Description

Multi-way tree in Pure Perl


Version "20210528".

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.

=head1 Index


=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Tree::Multi

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
#__DATA__
use Time::HiRes qw(time);
use Test::Most;

my $develop  = -e q(/home/phil/);                                               # Developing
my  $logFile = q(/home/phil/perl/cpan/TreeMulti/lib/Tree/zzzLog.txt);           # Log file

my $localTest = ((caller(1))[0]//'Tree::Multi') eq "Tree::Multi";               # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i) {plan tests => 21}                                    # Supported systems
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

bail_on_fail;

sub T($$)                                                                       #P Write a result to the log file
 {my ($tree, $expected) = @_;                                                   # Tree
  confess unless ref($tree);
  my $got = $tree->printKeys;
  my $s = showGotVersusWanted($got, $expected);
  return !$s unless $develop and $s;
  owf($logFile, $got);
  confess "$s\n";
 }

my $start = time;                                                               # Tests

eval {goto latest} if !caller(0) and -e "/home/phil";                           # Go to latest test if specified

if (1) {                                                                        #Tinsert #TprintKeys
  local $keysPerNode = 15;

  my $t = new; my $N = 256;

  $t = insert($t, $_, 2 * $_) for 1..$N;

  is_deeply $t->printKeys, <<END;
 72 144
   9 18 27 36 45 54 63
     1 2 3 4 5 6 7 8
     10 11 12 13 14 15 16 17
     19 20 21 22 23 24 25 26
     28 29 30 31 32 33 34 35
     37 38 39 40 41 42 43 44
     46 47 48 49 50 51 52 53
     55 56 57 58 59 60 61 62
     64 65 66 67 68 69 70 71
   81 90 99 108 117 126 135
     73 74 75 76 77 78 79 80
     82 83 84 85 86 87 88 89
     91 92 93 94 95 96 97 98
     100 101 102 103 104 105 106 107
     109 110 111 112 113 114 115 116
     118 119 120 121 122 123 124 125
     127 128 129 130 131 132 133 134
     136 137 138 139 140 141 142 143
   153 162 171 180 189 198 207 216 225 234 243
     145 146 147 148 149 150 151 152
     154 155 156 157 158 159 160 161
     163 164 165 166 167 168 169 170
     172 173 174 175 176 177 178 179
     181 182 183 184 185 186 187 188
     190 191 192 193 194 195 196 197
     199 200 201 202 203 204 205 206
     208 209 210 211 212 213 214 215
     217 218 219 220 221 222 223 224
     226 227 228 229 230 231 232 233
     235 236 237 238 239 240 241 242
     244 245 246 247 248 249 250 251 252 253 254 255 256
END

  if (1)                                                                        #Tfind
   {my $n = 0;
    for my $i(1..$N)
     {my $ii = $t->find($i);
       ++$n if $t->find($i) eq 2 * $i;
     }
    ok $n == $N;
   }
 }

if (1) {                                                                        #Tinsert #TprintKeys  #Tfind
  local $keysPerNode = 15;

  my $t = new; my $N = 256;

  $t = insert($t, $_, 2 * $_) for reverse map{scalar reverse} 1..$N;

  is_deeply $t->printKeys, <<END;
 371
   09 18 032 48 061 75 86 99 132 202 252 322
     001 002 03 04 05 06 07 08
     011 012 13 14 15 16 17
     19 021 022 23 24 25 26 27 28 29 031
     33 34 35 36 37 38 39 041 042 43 44 45 46 47
     49 051 052 53 54 55 56 57 58 59
     62 63 64 65 66 67 68 69 071 72 73 74
     76 77 78 79 081 82 83 84 85
     87 88 89 091 92 93 94 95 96 97 98
     101 102 111 112 121 122 131
     141 142 151 152 161 171 181 191 201
     211 212 221 222 231 232 241 242 251
     261 271 281 291 301 302 311 312 321
     331 332 341 342 351 352 361
   452 542 622 681 732 822 891
     381 391 401 402 411 412 421 422 431 432 441 442 451
     461 471 481 491 501 502 511 512 521 522 531 532 541
     551 552 561 571 581 591 601 602 611 612 621
     631 632 641 642 651 652 661 671
     691 701 702 711 712 721 722 731
     741 742 751 761 771 781 791 801 802 811 812 821
     831 832 841 842 851 861 871 881
     901 902 911 912 921 922 931 932 941 942 951 961 971 981 991
END

  if (1)
   {my $n = 0;
    for my $i(map {scalar reverse} 1..$N)
     {my $ii = $t->find($i);
       ++$n if $t->find($i) eq 2 * $i;
     }
    ok $n == $N;
   }
 }

if (1) {                                                                        #Tdelete
  local $keysPerNode = 3;

  my $t = new; my $N = 16;

  $t = insert($t, $_, 2 * $_) for 1..$N;

  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12 15
     7 8
     10 11
     13 14
     16
END

  $t = $t->delete(16);  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12 14
     7 8
     10 11
     13
     15
END

  $t = $t->delete(15);  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12
     7 8
     10 11
     13 14
END

  $t = $t->delete(14);  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 12
     7 8
     10 11
     13
END

  $t = $t->delete(13);  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9 11
     7 8
     10
     12
END

  $t = $t->delete(12);  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9
     7 8
     10 11
END

  $t = $t->delete(11);  ok T($t, <<END);
 6
   3
     1 2
     4 5
   9
     7 8
     10
END

  $t = $t->delete(10);  ok T($t, <<END);
 3 6 8
   1 2
   4 5
   7
   9
END

  $t = $t->delete(9); ok T($t, <<END);
 3 6
   1 2
   4 5
   7 8
END

  $t = $t->delete(8); ok T($t, <<END);
 3 6
   1 2
   4 5
   7
END

  $t = $t->delete(7); ok T($t, <<END);
 3 5
   1 2
   4
   6
END

  $t = $t->delete(6);  ok T($t, <<END);
 3
   1 2
   4 5
END

  $t = $t->delete(5);  ok T($t, <<END);
 3
   1 2
   4
END

  $t = $t->delete(4);  ok T($t, <<END);
 2
   1
   3
END

  $t = $t->delete(3);  ok T($t, <<END);
 1 2
END

  $t = $t->delete(2);  ok T($t, <<END);
 1
END

  $t = $t->delete(1);

  ok T($t, <<END);
END
 }

lll "Success:", time - $start;
