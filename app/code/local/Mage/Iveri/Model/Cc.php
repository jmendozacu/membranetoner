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
 * @category   Payments
 * @package    Vcs
 * @copyright  Copyright (c) 2008 W&C Information Consultants CC (http://www.wcic.co.za)
 */

class Mage_Iveri_Model_Cc extends Mage_Iveri_Model_Shared
{
    /**
    * unique internal payment method identifier
    *
    * @var string [a-z0-9_]
    **/
    protected $_code = 'iveri_cc';
    protected $_formBlockType = 'iveri/form';
    protected $_infoBlockType = 'iveri/info';
    protected $_paymentMethod = 'cc';

    protected $_Url = 'https://backoffice.nedsecure.co.za/Lite/Transactions/New/EasyAuthorise.aspx';
}                      