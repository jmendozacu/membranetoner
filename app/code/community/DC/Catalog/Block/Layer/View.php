<?php
/**
 * Magento
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the Open Software License (OSL 3.0)
 * that is bundled with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://opensource.org/licenses/osl-3.0.php
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@magentocommerce.com so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade Magento to newer
 * versions in the future. If you wish to customize Magento for your
 * needs please refer to http://www.magentocommerce.com for more information.
 *
 * @category    Mage
 * @package     Mage_Catalog
 * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
 * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */

/**
 * Catalog layered navigation view block
 *
 * @category    Mage
 * @package     Mage_Catalog
 * @author      Magento Core Team <core@magentocommerce.com>
 */
class DC_Catalog_Block_Layer_View extends Mage_Catalog_Block_Layer_View
{
    protected function _getFilterableAttributes()
    {
        $attributes = $this->getData('_filterable_attributes');
        if (is_null($attributes)) {
            $attributes = $this->getLayer()->getFilterableAttributes();
           	foreach ($attributes as $a) {
		        try {
                	//remove the current attribute from layered nav
            		if ($a->getAttributeCode() == Mage::registry('attribute_code')) {
            			$attributes->removeItemByKey($a->getId());
            		}
        	    } catch (Exception $e) {
            	}
            }
            //$attributes->removeItemByKey($this->getLayer()->getAttributeInfoPage()->getId())
            $this->setData('_filterable_attributes', $attributes);
        }
        return $attributes;
    }

	/**
     * Get layer object
     *
     * @return Mage_Catalog_Model_Layer
     */
    public function getLayer()
    {
    	//var_export(Mage::getSingleton('catalog/layer')->getAttributeInfoPage());
        return Mage::getSingleton('catalog/layer');
    }
}
