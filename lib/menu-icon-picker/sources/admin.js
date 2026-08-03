/**
 * Menu Icon Picker
 *
 * Font Awesome Picker modal on the nav menus screen.
 */
(function ($) {
	'use strict';

	// Font Awesome 6 icons in the picker grid.
	var FA_ICONS = [
		'fa-anchor', 'fa-asterisk', 'fa-atom', 'fa-award', 'fa-baby',
		'fa-bacon', 'fa-bacteria', 'fa-bag-shopping', 'fa-ban', 'fa-bandage',
		'fa-barcode', 'fa-bars', 'fa-baseball', 'fa-basketball', 'fa-bath',
		'fa-battery-empty', 'fa-battery-full', 'fa-bed', 'fa-bed-pulse', 'fa-beer-mug-empty',
		'fa-bell', 'fa-bicycle', 'fa-binoculars', 'fa-biohazard', 'fa-bitcoin-sign',
		'fa-blog', 'fa-bolt', 'fa-bolt-lightning', 'fa-bomb', 'fa-bone',
		'fa-bong', 'fa-book', 'fa-bookmark', 'fa-bottle-droplet', 'fa-bottle-water',
		'fa-bowling-ball', 'fa-box', 'fa-brain', 'fa-bread-slice', 'fa-bridge',
		'fa-briefcase', 'fa-broom', 'fa-brush', 'fa-bucket', 'fa-bug',
		'fa-bugs', 'fa-building', 'fa-bullhorn', 'fa-bullseye', 'fa-burger',
		'fa-bus', 'fa-calculator', 'fa-calendar', 'fa-camera', 'fa-camera-retro',
		'fa-campground', 'fa-candy-cane', 'fa-cannabis', 'fa-capsules', 'fa-car',
		'fa-carrot', 'fa-cart-shopping', 'fa-cash-register', 'fa-cat', 'fa-chair',
		'fa-chalkboard', 'fa-champagne-glasses', 'fa-cheese', 'fa-chess', 'fa-child',
		'fa-children', 'fa-church', 'fa-clipboard', 'fa-clock', 'fa-cloud',
		'fa-code', 'fa-coins', 'fa-comment', 'fa-comments', 'fa-compass',
		'fa-compress', 'fa-computer', 'fa-cookie', 'fa-copy', 'fa-couch',
		'fa-cow', 'fa-credit-card', 'fa-crow', 'fa-crown', 'fa-cube',
		'fa-cubes', 'fa-database', 'fa-diamond', 'fa-dice', 'fa-display',
		'fa-dna', 'fa-dog', 'fa-dollar-sign', 'fa-dove', 'fa-download',
		'fa-dragon', 'fa-draw-polygon', 'fa-drum', 'fa-dumpster', 'fa-dumpster-fire',
		'fa-dungeon', 'fa-egg', 'fa-elevator', 'fa-envelope', 'fa-eraser',
		'fa-ethernet', 'fa-exclamation', 'fa-explosion', 'fa-face-angry', 'fa-face-laugh',
		'fa-fan', 'fa-faucet', 'fa-faucet-drip', 'fa-feather', 'fa-file',
		'fa-film', 'fa-fingerprint', 'fa-fire', 'fa-fish', 'fa-flag',
		'fa-flask', 'fa-folder', 'fa-football', 'fa-frog', 'fa-gamepad',
		'fa-gas-pump', 'fa-gavel', 'fa-gear', 'fa-gears', 'fa-gem',
		'fa-genderless', 'fa-ghost', 'fa-gift', 'fa-gifts', 'fa-glasses',
		'fa-globe', 'fa-guitar', 'fa-gun', 'fa-hammer', 'fa-handshake',
		'fa-hard-drive', 'fa-hashtag', 'fa-headphones', 'fa-headset', 'fa-heart',
		'fa-helicopter', 'fa-highlighter', 'fa-hippo', 'fa-hockey-puck', 'fa-horse',
		'fa-hospital', 'fa-hotdog', 'fa-hotel', 'fa-hourglass', 'fa-house',
		'fa-hurricane', 'fa-ice-cream', 'fa-igloo', 'fa-image', 'fa-images',
		'fa-inbox', 'fa-info', 'fa-jar', 'fa-jedi', 'fa-jet-fighter',
		'fa-joint', 'fa-key', 'fa-keyboard', 'fa-laptop', 'fa-laptop-code',
		'fa-leaf', 'fa-lemon', 'fa-lightbulb', 'fa-link', 'fa-lock',
		'fa-magnet', 'fa-magnifying-glass', 'fa-map', 'fa-mars', 'fa-martini-glass',
		'fa-mask', 'fa-medal', 'fa-microphone', 'fa-mobile', 'fa-money-bill',
		'fa-moon', 'fa-mosquito', 'fa-motorcycle', 'fa-mountain', 'fa-music',
		'fa-newspaper', 'fa-oil-can', 'fa-pager', 'fa-paintbrush', 'fa-paper-plane',
		'fa-paperclip', 'fa-paste', 'fa-paw', 'fa-pen', 'fa-pencil',
		'fa-phone', 'fa-piggy-bank', 'fa-pills', 'fa-pizza-slice', 'fa-plane',
		'fa-play', 'fa-plug', 'fa-plus', 'fa-poo', 'fa-poo-storm',
		'fa-poop', 'fa-prescription', 'fa-prescription-bottle', 'fa-print', 'fa-puzzle-piece',
		'fa-question', 'fa-radiation', 'fa-radio', 'fa-rainbow', 'fa-ranking-star',
		'fa-recycle', 'fa-ribbon', 'fa-ring', 'fa-road', 'fa-robot',
		'fa-rocket', 'fa-rug', 'fa-ruler', 'fa-sailboat', 'fa-school',
		'fa-scissors', 'fa-screwdriver', 'fa-scroll', 'fa-server', 'fa-share',
		'fa-shield', 'fa-ship', 'fa-shirt', 'fa-shop', 'fa-shower',
		'fa-shrimp', 'fa-shuffle', 'fa-sink', 'fa-skull', 'fa-skull-crossbones',
		'fa-smoking', 'fa-snowflake', 'fa-snowman', 'fa-soap', 'fa-socks',
		'fa-spoon', 'fa-spray-can', 'fa-stairs', 'fa-stamp', 'fa-stapler',
		'fa-star', 'fa-stop', 'fa-store', 'fa-suitcase', 'fa-sun',
		'fa-syringe', 'fa-tablet', 'fa-tablets', 'fa-tag', 'fa-tags',
		'fa-tape', 'fa-taxi', 'fa-teeth', 'fa-tent', 'fa-terminal',
		'fa-thermometer', 'fa-thumbs-down', 'fa-thumbs-up', 'fa-ticket', 'fa-timeline',
		'fa-toilet', 'fa-toilet-paper', 'fa-toolbox', 'fa-tooth', 'fa-tornado',
		'fa-tractor', 'fa-traffic-light', 'fa-trailer', 'fa-train', 'fa-transgender',
		'fa-trash', 'fa-tree', 'fa-trophy', 'fa-truck', 'fa-tv',
		'fa-umbrella', 'fa-unlock', 'fa-upload', 'fa-user', 'fa-users',
		'fa-utensils', 'fa-vault', 'fa-vest', 'fa-video', 'fa-virus',
		'fa-viruses', 'fa-volcano', 'fa-volleyball', 'fa-walkie-talkie', 'fa-wallet',
		'fa-warehouse', 'fa-water', 'fa-wheelchair', 'fa-whiskey-glass', 'fa-wifi',
		'fa-wind', 'fa-wine-bottle', 'fa-wine-glass', 'fa-worm', 'fa-wrench',
		'fa-x-ray'	];

	var activeMenuItemId = null;

	function getNoResultsText() {
		return (window.mipPicker && mipPicker.i18n && mipPicker.i18n.noResults) || 'No icons found.';
	}

	function withStylePrefix(iconClass) {
		var hasStyle = /(^|\s)(fa|fas|far|fab|fal|fad|fa-solid|fa-regular|fa-brands|fa-light|fa-thin|fa-duotone)(\s|$)/;
		return hasStyle.test(iconClass) ? iconClass : 'fa-solid ' + iconClass;
	}

	function renderIconGrid(icons) {
		var $grid = $('#mip_icon-grid').empty();

		if (!icons.length) {
			$grid.html('<p class="mip_no-results">' + getNoResultsText() + '</p>');
			return;
		}

		var html = '';
		$.each(icons, function (i, iconClass) {
			var label = iconClass.replace('fa-brands ', '').replace('fa-', '');
			html += '<button type="button" class="mip_icon-btn" data-icon="' + iconClass + '" title="' + iconClass + '">';
			html += '<i class="' + withStylePrefix(iconClass) + '"></i>';
			html += '<span>' + label + '</span>';
			html += '</button>';
		});
		$grid.html(html);
	}

	function setMenuItemIcon($item, iconClass) {
		$item.find('input[name^="mip_icon["]').val(iconClass);
		$item.find('.mip_input-icon')
			.attr('class', 'mip_input-icon' + (iconClass ? ' ' + withStylePrefix(iconClass) : ''));
		$item.find('.mip_input-wrap').toggleClass('mip_has-icon', !!iconClass);
	}

	function initPicker() {
		var $modal = $('#mip_icon-picker-modal');
		if (!$modal.length) {
			return;
		}

		renderIconGrid(FA_ICONS);

		$(document).off('click.mipOpen', '.mip_open-picker').on('click.mipOpen', '.mip_open-picker', function (e) {
			e.preventDefault();
			activeMenuItemId = $(this).data('item-id');
			$('#mip_icon-search-input').val('');
			renderIconGrid(FA_ICONS);
			$modal.fadeIn(150);
		});

		$(document).off('click.mipClear', '.mip_clear-icon').on('click.mipClear', '.mip_clear-icon', function (e) {
			e.preventDefault();
			setMenuItemIcon($(this).closest('.menu-item'), '');
		});

		$modal.off('click.mipClose').on('click.mipClose', '.mip_modal-close, .mip_modal-overlay', function (e) {
			if (e.target === this || $(this).hasClass('mip_modal-close')) {
				$modal.fadeOut(150);
			}
		});

		$('#mip_icon-search-input').off('input.mipSearch').on('input.mipSearch', function () {
			var query = $(this).val().toLowerCase().trim();
			if (!query) {
				renderIconGrid(FA_ICONS);
				return;
			}
			renderIconGrid(FA_ICONS.filter(function (iconClass) {
				return iconClass.toLowerCase().indexOf(query) !== -1;
			}));
		});

		$('#mip_icon-grid').off('click.mipPick', '.mip_icon-btn').on('click.mipPick', '.mip_icon-btn', function () {
			if (activeMenuItemId) {
				setMenuItemIcon($('#menu-item-' + activeMenuItemId), $(this).data('icon'));
			}
			$modal.fadeOut(150);
		});
	}

	$(document).ready(initPicker);
})(jQuery);
