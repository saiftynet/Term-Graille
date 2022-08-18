use lib "../lib/";

use Term::Graille::Menu;


my $menu=new Term::Graille::Menu(
          menu=>[["File","New","Save","Load","Quit"],["Edit","Clear",["Reformat","2x4","4x4"],["Scroll","left","right","up","down"]],"About"],
          );

$menu->drawMenu();
sleep 1;
#print "--",@{$menu->drillDown()},"--\n";
sleep 1;
$menu->nextItem();
#print "--",@{$menu->drillDown()},"--\n";
sleep 1;
$menu->nextItem();
#print "--",@{$menu->drillDown()},"--\n";
sleep 1;
$menu->nextItem();
#print "--",@{$menu->drillDown()},"--\n";
sleep 1;
$menu->prevItem();
#print "--",@{$menu->drillDown()},"--\n";
sleep 1;
$menu->openItem();
#print "--",@{$menu->drillDown()},"--\n";
sleep 1;
$menu->nextItem();
#print "--",@{$menu->drillDown()},"--\n";
sleep 1;
$menu->openItem();
#print "--",@{$menu->drillDown()},"--\n";
sleep 1;
$menu->openItem();
#print "--",@{$menu->drillDown()},"--\n";


