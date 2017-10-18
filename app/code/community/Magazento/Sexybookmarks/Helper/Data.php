<?php
class Magazento_Sexybookmarks_Helper_Data extends Mage_Core_Helper_Abstract
{
    public function isBookmarksEnabled() {
       return Mage::getStoreConfig('sexybookmarks/options/enable');
    }
    
    public function printBookmarks($page_title,$page_url)
    {
        $list = Mage::getModel('sexybookmarks/list')->buildBookmarksList($page_title,$page_url);
        return $list;
    }


}
