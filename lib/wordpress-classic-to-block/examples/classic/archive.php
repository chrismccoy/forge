<?php get_header(); ?>
<main id="main" class="site-main">
    <div class="container">
        <?php if ( have_posts() ) : ?>
            <ul class="post-list">
            <?php while ( have_posts() ) : the_post(); ?>
                <li class="post-item">
                    <?php if ( has_post_thumbnail() ) : ?>
                        <a href="<?php the_permalink(); ?>">
                            <?php the_post_thumbnail( 'medium' ); ?>
                        </a>
                    <?php endif; ?>
                    <h2 class="entry-title">
                        <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                    </h2>
                    <p class="entry-meta">
                        <?php echo esc_html( get_the_date() ); ?>
                        — <?php the_author(); ?>
                    </p>
                    <?php the_excerpt(); ?>
                </li>
            <?php endwhile; ?>
            </ul>
            <?php the_posts_pagination(); ?>
        <?php else : ?>
            <p><?php esc_html_e( 'No posts found.', 'mytheme' ); ?></p>
        <?php endif; ?>
    </div>
</main>
<?php get_footer(); ?>
